/****************************************************************************
 * InboundQueue.java
 *
 * Copyright (C) Martin Woolley 2001
 *
 * This file is part of SMPPSim.
 *
 * SMPPSim is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * SMPPSim is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with SMPPSim; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * @author martin@seleniumsoftware.com
 * http://www.woolleynet.com
 * http://www.seleniumsoftware.com
 * $Header: /var/cvsroot/SMPPSim2/src/java/com/seleniumsoftware/SMPPSim/InboundQueue.java,v 1.14 2010/11/25 17:21:24 martin Exp $
 ****************************************************************************
 */
package com.seleniumsoftware.SMPPSim;

import com.seleniumsoftware.SMPPSim.exceptions.InboundQueueFullException;
import com.seleniumsoftware.SMPPSim.pdu.*;
import com.seleniumsoftware.SMPPSim.pdu.util.SeqnoStatus;
import com.seleniumsoftware.SMPPSim.util.*;
import java.util.logging.*;
import java.util.*;

public class InboundQueue implements Runnable {

	private static final int RESPONSE_WAIT_TIME = 5000;

	private static Logger logger = Logger
			.getLogger("com.seleniumsoftware.smppsim");

	private Smsc smsc = Smsc.getInstance();
	
	private static InboundQueue iqueue;
	
	private static DelayedInboundQueue diqueue;

	ArrayList<Pdu> inbound_queue;

	// we're waiting for a DELIVER_SM_RESP for each PDU in this queue. Depending on the command_status we then
	// either put the message into the delayed_inbound_queue or we simply delete it.
	ArrayList<Pdu> response_queue;
	
	SeqnoStatus response;
	Object response_mutex = new Object();

	// If no receiver session, message goes in the pending queue
	ArrayList<Pdu> pending_queue = new ArrayList<Pdu>();

	public static InboundQueue getInstance() {
		if (iqueue == null)
			iqueue = new InboundQueue(SMPPSim.getInbound_queue_capacity());
		return iqueue;
	}
	
	private InboundQueue(int maxsize) {
		inbound_queue = new ArrayList<Pdu>(maxsize);		
		response_queue = new ArrayList<Pdu>(maxsize);		
	}

	public void addMessage(Pdu message) throws InboundQueueFullException {
		synchronized (inbound_queue) {
			if (inbound_queue.size() >= smsc.getInbound_queue_capacity())
				throw new InboundQueueFullException();
			logger.finest("InboundQueue: adding object to queue<"
					+ message.toString() + ">");
			inbound_queue.add(message);
			logger.finest("InboundQueue: now contains " + inbound_queue.size()
					+ " object(s)");
			inbound_queue.notifyAll();
		}
	}

	public void deliveryResult(int seqno, int command_status) {
		logger.finest("MO message delivery attempted: seqno="+seqno+",status="+command_status+",responses pending="+response_queue.size());
		synchronized (response_queue) {
			for (int i=0;i<response_queue.size();i++) {
				Pdu pdu = response_queue.get(i);
				if (pdu.getSeq_no() == seqno) {
					if (command_status == PduConstants.ESME_RMSGQFUL) {
						logger.info("MO message "+seqno+" was rejected with queue full so putting in delayed inbound queue for retry");
						diqueue.retryLater(pdu);
					} else {
						// remove from the delayed inbound queue if the PDU originated from there
						diqueue.deliveredOK(pdu);
					}
					response_queue.remove(i);
					synchronized (response_mutex) {
						response = new SeqnoStatus(seqno, command_status);
						response_mutex.notifyAll();
					}
					break;
				}
			}
		}
		logger.finest("Awaiting " + response_queue.size()+" responses");
	}

	public void removeMessage(Pdu m) {
		removeMessage(m, inbound_queue);
	}

	public void removeMessage(Pdu m, ArrayList<Pdu> queue) {
		logger.finest("Removing PDU from queue. Queue currently contains:"+queue.size());
		for (int i=0;i<queue.size();i++) {
			logger.finest(((Pdu) queue.get(i)).toString());
		}
		synchronized (queue) {
			int i = queue.indexOf(m);
			if (i > -1) {
				queue.remove(i);
			} else {
				logger
						.warning("Attempt to remove non-existent object from InboundQueue: "
								+ m.toString());
			}
		}
		logger.finest("Queue now contains:"+queue.size());
	}

	private Pdu[] getAllMessages() {
		synchronized (inbound_queue) {
			Pdu[] o = inbound_queue.toArray(new Pdu[inbound_queue.size()]);
			return o;
		}
	}

	private boolean isEmpty() {
		return inbound_queue.isEmpty();
	}

	public int size() {
		return inbound_queue.size();
	}

	public int pending_size() {
		return pending_queue.size();
	}

	public void notifyReceiverBound() {
		synchronized (inbound_queue) {
			logger
					.finest("A receiver bound - will notify InboundQueue service");
			inbound_queue.notifyAll();
		}
	}

	public void run() {
		// this code processes the contents of the InboundQueue
		// Each object in the queue is either a delivery receipt or
		// a MO message created by the MO Service or via the loopback
		// mechanism. Either way, they're all DELIVER_SM PDUs

		// The InboundQueue gets processed as follows:
		//
		//	Wait until
		//		there is at least one receiver session
		//		and at least one message in the queue
		//	Then
		//		get all messages from the queue
		//		for each message
		//			see if there is a receiver whose address_range matches the message and if so, attempt to deliver it and
		//			move it from the inbound queue to the response queue.
		//			Later we get informed of the result of the delivery attempt; If the delivery attempt failed
		//			with ESME_RMSGQFUL then we move the message to the delayed_inbound_queue and try to deliver it
		//			again later.

		logger.info("Starting InboundQueue service....");

		diqueue = DelayedInboundQueue.getInstance();
		Thread t = new Thread(diqueue);
		t.start();

		do // process queue forever
		{
			processQueue();
		} while (true);
	}
	
	private void addPendingQueue(Pdu mo) {
		pending_queue.add(mo);	
		if (SMPPSim.isOutbind_enabled() && !smsc.isOutbind_sent()) {
			smsc.outbind();
			// should reset the outbind_sent flag now ready for the next time
		}
	}

	private void processQueue() {
		StandardConnectionHandler receiver = null;
		Pdu[] pdus;
		DeliverSM pdu;
		byte[] message;
		byte[] response;
		String pduName;
		int pduCount;

		synchronized (inbound_queue) {
			while (isEmpty() || (smsc.getReceiverBoundCount() == 0)) {
				try {
					if (isEmpty()) {
						logger.info("InboundQueue: empty  - waiting");
					} else {
						logger
								.info("InboundQueue: no available receiver sessions - moving message(s) to pending queue");
						int pc = 0;
						synchronized (pending_queue) {
							Pdu [] active_pdus = (Pdu[]) inbound_queue.toArray();
							for (int i=0;i<active_pdus.length;i++) {
								Pdu mo = active_pdus[i];
								addPendingQueue(mo);
								removeMessage(mo);
								pc++;
							}
						}
						logger.info("Moved " + pc
								+ " MO messages to the pending queue");

					}
					inbound_queue.wait();
				} catch (InterruptedException e) {
					logger.log(Level.WARNING, "Exception in InboundQueue: "
							+ e.getMessage(), e);
				}
			}
		}
		if (smsc.getReceiverBoundCount() != 0) {
			pdus = getAllMessages();
			pduCount = pdus.length;
			logger.finest("Attempting to deliver " + pduCount
					+ " messages from InboundQueue");

			int i = 0;
			boolean continuing = true;
			while (i < pduCount && continuing) {
				if (pdus[i] instanceof DeliverSM) {
					continuing = processDeliverSM((DeliverSM) pdus[i], receiver,inbound_queue);
				} else {
					continuing = processDataSM((DataSM) pdus[i], receiver);
				}
				i++;
			}
		}
	}


	protected boolean processDeliverSM(DeliverSM pdu, StandardConnectionHandler receiver, ArrayList <Pdu> from_queue) {
		String pduName;
		byte[] message;

		if (pdu instanceof DeliveryReceipt)
			pduName = "DELIVER_SM (receipt):";
		else
			pduName = "DELIVER_SM:";

		try {
			message = pdu.marshall();
			LoggingUtilities.hexDump(pduName, message, message.length);
			if (smsc.isDecodePdus())
				LoggingUtilities.logDecodedPdu(pdu);
			logger.info(" ");
			receiver = smsc.selectReceiver(pdu.getDestination_addr());
			if (receiver == null) {
				logger
						.warning("InboundQueue: no active receiver object to deliver message. Application must issue BIND_RECEIVER with approriate address_range. Message has been moved to the pending queue");
				removeMessage(pdu, from_queue);
				addPendingQueue(pdu);
				if (smsc.getReceiverBoundCount() == 0) {
					logger
							.info("No receiver sessions bound - suspending InboundQueue processing");
					return false;
				}
			} else {
				try {
					smsc.writeDecodedSmppsim(pdu.toString());
					receiver.writeResponse(message);
					synchronized (response_queue) {
						response_queue.add(pdu);
						logger.finest("Added message "+pdu.getSeq_no()+" to response queue");
					}
					removeMessage(pdu, from_queue);
					awaitResponse(pdu);
				} catch (Exception e) {
					logger.log(Level.WARNING, "Exception in InboundQueue: "
							+ e.getMessage(), e);
				}
			}
		} catch (Exception ex) {
			logger
					.log(
							Level.WARNING,
							"Exception whilst marshalling PDU from InboundQueue. Message discarded",
							ex);
		}

		return true;
	}

	protected boolean processDataSM(DataSM pdu,
			StandardConnectionHandler receiver) {
		byte[] message;

		try {
			message = pdu.marshall();
			LoggingUtilities.hexDump("DATA_SM:", message, message.length);
			if (smsc.isDecodePdus())
				LoggingUtilities.logDecodedPdu(pdu);
			logger.info(" ");
			receiver = smsc.selectReceiver(pdu.getDestination_addr());
			if (receiver == null) {
				logger
						.warning("InboundQueue: no active receiver object to deliver message. Application must issue BIND_RECEIVER with approriate address_range. Message deleted from the inbound queue.");
				removeMessage(pdu);
				if (smsc.getReceiverBoundCount() == 0) {
					logger
							.info("No receiver sessions bound - suspending InboundQueue processing");
					return false;
				}
			} else {
				try {
					smsc.writeDecodedSmppsim(pdu.toString());
					receiver.writeResponse(message);
					removeMessage(pdu);
					smsc.incDataSmOK();
					awaitResponse(pdu);
				} catch (Exception e) {
					logger.log(Level.WARNING, "Exception in InboundQueue: "
							+ e.getMessage(), e);
					smsc.incDataSmERR();
				}
			}
		} catch (Exception ex) {
			logger
					.log(
							Level.WARNING,
							"Exception whilst marshalling PDU from InboundQueue. Message discarded",
							ex);
		}

		return true;
	}

	private void awaitResponse(Pdu pdu) {
		// now wait for the response. This makes us synchronous i.e. no windowing.
		// needs to have timeout and seqno checking
		long wait_time_so_far=0;
		long wait_start=System.currentTimeMillis();
		long max_time_to_wait = RESPONSE_WAIT_TIME;
		synchronized (response_mutex) {
			boolean awaiting_response = true;
			while (awaiting_response) {
				try {
					logger.info("Waiting for response with seqno="+pdu.getSeq_no());
					response_mutex.wait(max_time_to_wait);
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
				// check seqno. If as expected, allow processing to proceed to the next PDU.
				// if not expected seqno.....
				if (response != null) {
					logger.info("Got response with seqno="+response.getSeq_no());
					if (pdu.getSeq_no() == response.getSeq_no()) {
						// we're good to go
						awaiting_response = false;
					} else {
						logger.warning("Got unexpected response PDU. Expected seqno "+pdu.getSeq_no()+" but received "+response.getSeq_no());
						wait_time_so_far = System.currentTimeMillis() - wait_start;
						if (wait_time_so_far >= RESPONSE_WAIT_TIME) {
							// give up waiting
							awaiting_response = false;
						} else {
							// we'll discard this response and wait again for the next PDU 
							response = null;
							max_time_to_wait = max_time_to_wait - wait_time_so_far;
							if (max_time_to_wait <= 0) {
								awaiting_response = false;
							}
						}
					}
				} else {
					// give up waiting
					awaiting_response = false;
				}
			}
			response = null;
			response_mutex.notifyAll();
		}
	}

	/**
	 * Called when a receiver or transceiver session is established. Results in any MO messages for which a session
	 * was not available originally and which were set to one side in the pending queue, being delivered if the new session
	 * is suitable.
	 *
	 */
	public void deliverPendingMoMessages() {
		Object[] messages = null;
		synchronized (pending_queue) {
			messages = pending_queue.toArray();
		}
		int l = messages.length;

		for (int i = 0; i < l; i++) {
			boolean ok = processDeliverSM((DeliverSM) messages[i], null, pending_queue);
			if (!ok)
				break;
		}

		// reset the outbind flag ready for the next time
		smsc.setOutbind_sent(false);

	}
}