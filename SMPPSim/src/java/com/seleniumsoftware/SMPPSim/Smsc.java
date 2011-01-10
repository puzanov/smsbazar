/****************************************************************************
 * Smsc.java
 *
 * Copyright (C) Selenium Software Ltd 2006
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
 * $Header: /var/cvsroot/SMPPSim2/src/java/com/seleniumsoftware/SMPPSim/Smsc.java,v 1.17 2010/11/25 17:21:24 martin Exp $
 ****************************************************************************/

package com.seleniumsoftware.SMPPSim;

import com.seleniumsoftware.SMPPSim.exceptions.*;
import com.seleniumsoftware.SMPPSim.pdu.*;
import com.seleniumsoftware.SMPPSim.pdu.util.PduUtilities;
import com.seleniumsoftware.SMPPSim.util.*;

import java.util.*;
import java.text.*;
import java.util.logging.*;
import java.io.File;
import java.io.IOException;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.OutputStream;
import java.net.*;

public class Smsc {

	private static Smsc smsc;

	private Socket callback;

	private OutputStream callback_stream;

	private boolean callback_server_online = false;

	private Logger logger = Logger.getLogger("com.seleniumsoftware.smppsim");

	private long message_id = 0;

	private int sequence_no = 0;

	private byte[] SMSC_SYSTEMID;

	private boolean decodePdus;

	private int receiverIndex = 0;

	private StandardConnectionHandler[] connectionHandlers;

	private ServerSocket smpp_ss;

	private HttpHandler[] httpcontrollers;

	private ServerSocket css;

	private MoService ds;

	private Thread deliveryService;

	private InboundQueue iq;

	private OutboundQueue oq;

	private DelayedDrQueue drq;

	private LifeCycleManager lcm;

	private Thread lifecycleService;

	private Thread inboundQueueService;

	private int inbound_queue_capacity = 100;

	private int outbound_queue_capacity = 100;

	// PDU capture

	private File smeBinaryFile;

	private FileOutputStream smeBinary;

	private File smppsimBinaryFile;

	private FileOutputStream smppsimBinary;

	private File smeDecodedFile;

	private FileWriter smeDecoded;

	private File smppsimDecodedFile;

	private FileWriter smppsimDecoded;

	// Stats

	private Date startTime;

	private String startTimeString;

	private int txBoundCount = 0;

	private int rxBoundCount = 0;

	private int trxBoundCount = 0;

	private long bindTransmitterOK = 0;

	private long bindTransceiverOK = 0;

	private long bindReceiverOK = 0;

	private long bindTransmitterERR = 0;

	private long bindTransceiverERR = 0;

	private long bindReceiverERR = 0;

	private long submitSmOK = 0;

	private long submitSmERR = 0;

	private long submitMultiOK = 0;

	private long submitMultiERR = 0;

	private long deliverSmOK = 0;

	private long deliverSmERR = 0;

	private long querySmOK = 0;

	private long querySmERR = 0;

	private long cancelSmOK = 0;

	private long cancelSmERR = 0;

	private long replaceSmOK = 0;

	private long replaceSmERR = 0;

	private long enquireLinkOK = 0;

	private long enquireLinkERR = 0;

	private long unbindOK = 0;

	private long unbindERR = 0;

	private long genericNakOK = 0;

	private long genericNakERR = 0;

	private long dataSmOK = 0;

	private long dataSmERR = 0;
	
	private long outbindOK = 0;
	
	private long outbindERR = 0;
	
	// outbind
	
	boolean outbind_sent = false;
	
	private Smsc() {
	}

	public static synchronized Smsc getInstance() {
		if (smsc == null)
			smsc = new Smsc();
		return smsc;
	}

	public synchronized  void start() throws Exception {

		startTime = new Date();
		SimpleDateFormat df = new SimpleDateFormat("EEE, d MMM yyyy HH:mm:ss");
		startTimeString = df.format(startTime);
		
		message_id = SMPPSim.getStart_at();

		if (SMPPSim.isCallback()) {
			connectToCallbackServer(new Object());
		}

		if (SMPPSim.isCaptureSmeBinary()) {
			System.out.println("Creating smeBinaryCapture file");
			smeBinaryFile = new File(SMPPSim.getCaptureSmeBinaryToFile());
			smeBinaryFile.delete();
			System.out.println(smeBinaryFile.createNewFile());
			smeBinary = new FileOutputStream(smeBinaryFile);
		}

		if (SMPPSim.isCaptureSmppsimBinary()) {
			smppsimBinaryFile = new File(SMPPSim
					.getCaptureSmppsimBinaryToFile());
			smppsimBinaryFile.delete();
			smppsimBinaryFile.createNewFile();
			smppsimBinary = new FileOutputStream(smppsimBinaryFile);
		}

		if (SMPPSim.isCaptureSmeDecoded()) {
			smeDecodedFile = new File(SMPPSim.getCaptureSmeDecodedToFile());
			smeDecodedFile.delete();
			smeDecodedFile.createNewFile();
			smeDecoded = new FileWriter(smeDecodedFile);
		}

		if (SMPPSim.isCaptureSmppsimDecoded()) {
			smppsimDecodedFile = new File(SMPPSim
					.getCaptureSmppsimDecodedToFile());
			smppsimDecodedFile.delete();
			smppsimDecodedFile.createNewFile();
			smppsimDecoded = new FileWriter(smppsimDecodedFile);
		}

		iq = InboundQueue.getInstance();

		Class cl = Class.forName(SMPPSim.getLifeCycleManagerClassName());
		lcm = (LifeCycleManager) cl.newInstance();

		oq = new OutboundQueue(outbound_queue_capacity);

		Thread smppThread[] = new Thread[SMPPSim.getMaxConnectionHandlers()];
		int threadIndex = 0;
		connectionHandlers = new StandardConnectionHandler[SMPPSim
				.getMaxConnectionHandlers()];
		try {
			smpp_ss = new ServerSocket(SMPPSim.getSmppPort(), 10);
		} catch (Exception e) {
			logger.severe("Exception creating SMPP server: " + e.toString());
			e.printStackTrace();
			throw e;
		}
		for (int i = 0; i < SMPPSim.getMaxConnectionHandlers(); i++) {
			Class c = Class.forName(SMPPSim.getConnectionHandlerClassName());
			StandardConnectionHandler ch = (StandardConnectionHandler) c
					.newInstance();
			ch.setSs(smpp_ss);
			connectionHandlers[threadIndex] = ch;
			smppThread[threadIndex] = new Thread(
					connectionHandlers[threadIndex], "CH" + threadIndex);
			smppThread[threadIndex].start();
			threadIndex++;
		}

		try {
			css = new ServerSocket(SMPPSim.getHTTPPort(), 10);
		} catch (Exception e) {
			logger.warning("Exception creating HTTP server: " + e.toString());
			e.printStackTrace();
		}
		Thread cthread[] = new Thread[SMPPSim.getHTTPThreads()];
		httpcontrollers = new HttpHandler[SMPPSim.getHTTPThreads()];
		for (int i = 0; i < SMPPSim.getHTTPThreads(); i++) {
			httpcontrollers[i] = new HttpHandler(new File(SMPPSim.getDocroot()));
			cthread[i] = new Thread(httpcontrollers[i], "HC" + i);
			cthread[i].start();
		}
		if (SMPPSim.getDeliverMessagesPerMin() != 0) {
			ds = new MoService(SMPPSim.getDeliverFile(), SMPPSim
					.getDeliverMessagesPerMin());
		}

		// InboundQueue must always be running to allow for MO messages injected
		// via web interface
		inboundQueueService = new Thread(iq);
		inboundQueueService.start();

		// LifeCycleService (OutboundQueue) must always be running
		lifecycleService = new Thread(oq);
		lifecycleService.start();
		
		if (SMPPSim.getDelayReceiptsBy() > 0) {
			logger.info("Starting delivery receipts delay service....");
			drq = DelayedDrQueue.getInstance();
			Thread t = new Thread(drq);
			t.start();
		}
	}

	public synchronized  boolean authenticate(String systemid, String password) {
		
		for (int i=0;i<SMPPSim.getSystemids().length;i++) {
			if (SMPPSim.getSystemids()[i].equals(systemid))
				if (SMPPSim.getPasswords()[i].equals(password))
					return true;
				else
					return false;
		}
		return false;		
	}

	public synchronized  boolean isValidSystemId(String systemid) {
		
		for (int i=0;i<SMPPSim.getSystemids().length;i++) {
			if (SMPPSim.getSystemids()[i].equals(systemid))
				return true;
		}
		return false;		
	}

	public synchronized  void connectToCallbackServer(Object mutex) {
		CallbackServerConnector cbs = new CallbackServerConnector(mutex);
		Thread cbst = new Thread(cbs);
		cbst.start();
	}

	public synchronized String getMessageID() {
		long msgID = message_id++;
		String msgIDstr = SMPPSim.getMid_prefix()+Long.toString(msgID);
		return msgIDstr;
	}

	public synchronized  int getNextSequence_No() {
		sequence_no++;
//		logger.info("SeqNo was set to "+sequence_no);
		return sequence_no;
	}

	public QuerySMResp querySm(QuerySM q, QuerySMResp r)
			throws MessageStateNotFoundException {
		MessageState m = new MessageState();
		m = oq.queryMessageState(q.getOriginal_message_id(), q
				.getOriginating_ton(), q.getOriginating_npi(), q
				.getOriginating_addr());
		r.setMessage_state(m.getState());
		if (m.getFinalDate() != null)
			r.setFinal_date(m.getFinalDate().getDateString());
		else
			r.setFinal_date("");
		return r;
	}

	public CancelSMResp cancelSm(CancelSM q, CancelSMResp r)
			throws MessageStateNotFoundException, InternalException {
		MessageState m = new MessageState();
		// messageid specified
		if ((!q.getOriginal_message_id().equals(""))) {
			m = oq.queryMessageState(q.getOriginal_message_id(), q
					.getSource_addr_ton(), q.getSource_addr_npi(), q
					.getSource_addr());
			r.setSeq_no(q.getSeq_no());
			oq.removeMessageState(m);
			return r;
		}
		// messageid null (in PDU), service_type specified
		if ((q.getOriginal_message_id().equals(""))
				&& (!q.getService_type().equals(""))) {
			int c = cancelMessages(q.getService_type(), q.getSource_addr_ton(),
					q.getSource_addr_npi(), q.getSource_addr(), q
							.getDest_addr_ton(), q.getDest_addr_npi(), q
							.getDestination_addr());
			logger.info(c + " messages cancelled");
			r.setSeq_no(q.getSeq_no());
			return r;
		}
		// messageid null (in PDU), service_type null also
		if ((q.getOriginal_message_id().equals(""))
				&& (q.getService_type().equals(""))) {
			int c = cancelMessages(q.getSource_addr_ton(), q
					.getSource_addr_npi(), q.getSource_addr(), q
					.getDest_addr_ton(), q.getDest_addr_npi(), q
					.getDestination_addr());
			logger.info(c + " messages cancelled");
			r.setSeq_no(q.getSeq_no());
			return r;
		}
		logger
				.severe("Laws of physics violated. Well laws of logic anyway. Fell through conditions in Smsc.cancelSm");
		logger.severe("Request is:" + q.toString());
		throw new InternalException(
				"Laws of physics violated. Well laws of logic anyway. Fell through conditions in Smsc.cancelSm");
	}

	private int cancelMessages(String service_type, int source_addr_ton,
			int source_addr_npi, String source_addr, int dest_addr_ton,
			int dest_addr_npi, String destination_addr) {

		Object[] messages = oq.getAllMessageStates();
		MessageState m;
		int s = messages.length;
		int c = 0;
		for (int i = 0; i < s; i++) {
			m = (MessageState) messages[i];
			if (m.getPdu().getService_type().equals(service_type)
					&& m.getPdu().getSource_addr_ton() == source_addr_ton
					&& m.getPdu().getSource_addr_npi() == source_addr_npi
					&& m.getPdu().getSource_addr().equals(source_addr)
					&& m.getPdu().getDest_addr_ton() == dest_addr_ton
					&& m.getPdu().getDest_addr_npi() == dest_addr_npi
					&& m.getPdu().getDestination_addr()
							.equals(destination_addr)) {
				c++;
				oq.removeMessageState(m);
			}
		}
		return c;
	}

	private int cancelMessages(int source_addr_ton, int source_addr_npi,
			String source_addr, int dest_addr_ton, int dest_addr_npi,
			String destination_addr) {
		Object[] messages = oq.getAllMessageStates();
		MessageState m;
		int s = messages.length;
		int c = 0;
		for (int i = 0; i < s; i++) {
			m = (MessageState) messages[i];
			if (m.getPdu().getSource_addr_ton() == source_addr_ton
					&& m.getPdu().getSource_addr_npi() == source_addr_npi
					&& m.getPdu().getSource_addr().equals(source_addr)
					&& m.getPdu().getDest_addr_ton() == dest_addr_ton
					&& m.getPdu().getDest_addr_npi() == dest_addr_npi
					&& m.getPdu().getDestination_addr()
							.equals(destination_addr)) {
				c++;
				oq.removeMessageState(m);
			}
		}
		return c;
	}

	public ReplaceSMResp replaceSm(ReplaceSM q, ReplaceSMResp r)
			throws MessageStateNotFoundException {
		MessageState m = new MessageState();
		m = oq.queryMessageState(q.getMessage_id(), q.getSource_addr_ton(), q
				.getSource_addr_npi(), q.getSource_addr());
		SubmitSM pdu = m.getPdu();
		if (q.getSchedule_delivery_time() != null)
			pdu.setSchedule_delivery_time(q.getSchedule_delivery_time());
		if (q.getValidity_period() != null)
			pdu.setValidity_period(q.getValidity_period());
		pdu.setRegistered_delivery_flag(q.getRegistered_delivery_flag());
		pdu.setSm_default_msg_id(q.getSm_default_msg_id());
		pdu.setSm_length(q.getSm_length());
		pdu.setShort_message(q.getShort_message());
		m.setPdu(pdu);
		oq.updateMessageState(m);
		logger.info("MessageState replaced with " + m.toString());
		r.setSeq_no(q.getSeq_no());
		return r;
	}

	public synchronized void receiverUnbound() {
		SMPPSim.decrementBoundReceiverCount();
		SMPPSim.showReceiverCount();
		if (SMPPSim.getBoundReceiverCount() == 0) {
			stopMoService();
		}
	}

	public synchronized  int getReceiverBoundCount() {
		return SMPPSim.getBoundReceiverCount();
	}

	public StandardConnectionHandler selectReceiver(String address) {
		boolean gotReceiver = false;
		int receiversChecked = 0;
		logger.finest("Smsc: selectReceiver");
		do {
			receiverIndex = getNextReceiverIndex();
			if ((connectionHandlers[receiverIndex].isBound())
					&& (connectionHandlers[receiverIndex].isReceiver())
					&& (connectionHandlers[receiverIndex]
							.addressIsServicedByReceiver(address))) {
				gotReceiver = true;
			} else {
				receiversChecked++;
			}
		} while ((!gotReceiver)
				&& (receiversChecked <= SMPPSim.getMaxConnectionHandlers()));

		logger.finest("Smsc: Using SMPPReceiver object #" + receiverIndex);
		if (gotReceiver) {
			return connectionHandlers[receiverIndex];
		} else {
			logger.warning("Smsc: No receiver for message address to "
					+ address);
			return null;
		}
	}

	public synchronized  void doLoopback(SubmitSM smppmsg) throws InboundQueueFullException {
		DeliverSM newMessage = new DeliverSM(smppmsg);
		iq.addMessage(newMessage);
	}

	public synchronized  void doLoopback(DataSM smppmsg) throws InboundQueueFullException {
		DataSM newMessage = new DataSM(smppmsg);
		iq.addMessage(newMessage);
	}

	public synchronized  void doEsmeToEsmeDelivery(SubmitSM smppmsg) throws InboundQueueFullException {
		DeliverSM newMessage = new DeliverSM();
		newMessage.esmeToEsmeDerivation(smppmsg);
		iq.addMessage(newMessage);
	}

	public synchronized  void outbind() {
		try {
			Socket s = new Socket(SMPPSim.getEsme_ip_address(),SMPPSim.getEsme_port());
			OutputStream out = s.getOutputStream();
			Outbind outbind = new Outbind(SMPPSim.getEsme_systemid(),SMPPSim.getEsme_password());
			byte [] outbind_bytes = outbind.marshall();
			LoggingUtilities.hexDump(": OUTBIND:", outbind_bytes, outbind_bytes.length);
			if (isDecodePdus())
				LoggingUtilities.logDecodedPdu(outbind);
			out.write(outbind_bytes);
			out.flush();
			out.close();
			s.close();
			outbindOK++;
			outbind_sent = true;
		} catch (Exception e) {
			logger.warning("Attempted outbind failed. Check IP address and port are correct for outbind. Exception of type "+e.getClass().getName());
			outbindERR++;
		}
	}
	
	public synchronized  void prepareDeliveryReceipt(SubmitSM smppmsg, String messageID,	byte state, int sub, int dlvrd, int err) {
		int esm_class=4;
		if (state == PduConstants.ENROUTE)
			esm_class = 32;
		DeliveryReceipt receipt = new DeliveryReceipt(smppmsg,esm_class);
		Date rightNow = new Date();
		SimpleDateFormat df = new SimpleDateFormat("yyMMddHHmm");
		String dateAsString = df.format(rightNow);
		receipt.setMessage_id(messageID);
		String s = "000" + sub;
		int l = s.length();
		receipt.setSub(s.substring(l - 3, l));
		s = "000" + dlvrd;
		l = s.length();
		receipt.setDlvrd(s.substring(l - 3, l));
		receipt.setSubmit_date(dateAsString);
		receipt.setDone_date(dateAsString);
		String err_string = "000" + err;
		err_string = err_string.substring(err_string.length()-3,err_string.length());
		receipt.setErr(err_string);
		logger.finest("sm_len=" + smppmsg.getSm_length() + ",message="
				+ smppmsg.getShort_message());
		if (smppmsg.getSm_length() > 19)
			receipt.setText(new String(smppmsg.getShort_message(),0, 20));
		else
			if (smppmsg.getSm_length() > 0)
				receipt.setText(new String(smppmsg.getShort_message(),0,
						smppmsg.getSm_length()));
		receipt.setDeliveryReceiptMessage(state);
		try {
			if (SMPPSim.getDelayReceiptsBy() <= 0) {
				iq.addMessage(receipt);
			} else {
				drq.delayDeliveryReceipt(receipt);
			}
		} catch (InboundQueueFullException e) {
			logger
					.warning("Failed to create delivery receipt because the Inbound Queue is full");
		}
	}

	private synchronized int getNextReceiverIndex() {
		if (receiverIndex == (SMPPSim.getMaxConnectionHandlers() - 1)) {
			receiverIndex = 0;
		} else {
			receiverIndex++;
		}
		return receiverIndex;
	}

	public synchronized byte[] processDeliveryReceipt(DeliveryReceipt smppmsg)
			throws Exception {
		byte[] message;
		logger.finest(": DELIVER_SM (receipt)");
		message = smppmsg.marshall();
		LoggingUtilities.hexDump("DELIVER_SM (receipt):", message,
				message.length);
		return message;
	}

	public synchronized void setMoServiceRunning() {
		SMPPSim.incrementBoundReceiverCount();
		SMPPSim.showReceiverCount();
		if ((SMPPSim.getDeliverMessagesPerMin() > 0) && (!ds.moServiceRunning)) {
			ds.moServiceRunning = true;
			deliveryService = new Thread(ds, "MO");
			deliveryService.start();
		}
	}

	public synchronized void stopMoService() {
		if (ds != null) {
			if (ds.moServiceRunning) {
				logger.info("Stopping MO service");
				ds.moServiceRunning = false;
			}
		}
	}

	public synchronized void stop() {
		// TODO implement stop action
	}

	public synchronized void writeBinarySme(byte[] request) throws IOException {
		if (SMPPSim.isCaptureSmeBinary()) {
			smeBinary.write(request);
			smeBinary.flush();
		}
	}

	public synchronized void writeBinarySmppsim(byte[] response) throws IOException {
		if (SMPPSim.isCaptureSmppsimBinary()) {
			smppsimBinary.write(response);
			smppsimBinary.flush();
		}
	}

	public synchronized void writeDecodedSme(String request) throws IOException {
		if (SMPPSim.isCaptureSmeDecoded()) {
			smeDecoded.write(request + "\n");
			smeDecoded.flush();
		}
	}

	public synchronized void writeDecodedSmppsim(String response) throws IOException {
		if (SMPPSim.isCaptureSmppsimDecoded()) {
			smppsimDecoded.write(response + "\n");
			smppsimDecoded.flush();
		}
	}

	/**
	 * @return
	 */
	public synchronized byte[] getSMSC_SYSTEMID() {
		return SMSC_SYSTEMID;
	}

	/**
	 * @param bs
	 */
	public synchronized void setSMSC_SYSTEMID(byte[] bs) {
		SMSC_SYSTEMID = bs;
	}

	/**
	 * @return
	 */
	public synchronized long getMessage_id() {
		return message_id;
	}

	/**
	 * @return
	 */
	public synchronized int getSequence_no() {
		return sequence_no;
	}

	/**
	 * @param l
	 */
	public synchronized void setMessage_id(long l) {
		message_id = l;
	}

	/**
	 * @param i
	 */
	public synchronized void setSequence_no(int i) {
		sequence_no = i;
	}

	/**
	 * @return
	 */
	public synchronized ServerSocket getCss() {
		return css;
	}

	/**
	 * @return
	 */
	public synchronized boolean isDecodePdus() {
		return decodePdus;
	}

	/**
	 * @param b
	 */
	public synchronized void setDecodePdus(boolean b) {
		decodePdus = b;
	}

	/**
	 * @return
	 */
	public synchronized InboundQueue getIq() {
		return iq;
	}

	/**
	 * @return
	 */
	public synchronized OutboundQueue getOq() {
		return oq;
	}

	/**
	 * @return
	 */
	public synchronized int getInbound_queue_capacity() {
		return inbound_queue_capacity;
	}

	/**
	 * @return
	 */
	public synchronized int getInbound_queue_size() {
		return iq.size();
	}

	public synchronized int getPending_queue_size() {
		return iq.pending_size();
	}

	/**
	 * @return
	 */
	public synchronized int getOutbound_queue_capacity() {
		return outbound_queue_capacity;
	}

	/**
	 * @return
	 */
	public synchronized int getOutbound_queue_size() {
		return oq.size();
	}

	/**
	 * @param i
	 */
	public synchronized void setInbound_queue_capacity(int i) {
		inbound_queue_capacity = i;
	}

	/**
	 * @param i
	 */
	public synchronized void setOutbound_queue_capacity(int i) {
		outbound_queue_capacity = i;
	}

	/**
	 * @return
	 */
	public synchronized LifeCycleManager getLcm() {
		return lcm;
	}

	/**
	 * @return
	 */
	public synchronized String getStartTimeString() {
		return startTimeString;
	}

	/**
	 * @return
	 */
	public synchronized int getRxBoundCount() {
		return rxBoundCount;
	}

	/**
	 * @return
	 */
	public synchronized int getTrxBoundCount() {
		return trxBoundCount;
	}

	/**
	 * @return
	 */
	public synchronized int getTxBoundCount() {
		return txBoundCount;
	}

	/**
	 * @param i
	 */
	public synchronized void setRxBoundCount(int i) {
		logger.info("Set RxBoundCount to " + i);
		rxBoundCount = i;
	}

	/**
	 * @param i
	 */
	public synchronized void setTrxBoundCount(int i) {
		trxBoundCount = i;
	}

	/**
	 * @param i
	 */
	public synchronized void setTxBoundCount(int i) {
		txBoundCount = i;
	}

	public synchronized void incTxBoundCount() {
		txBoundCount++;
	}

	public synchronized void incRxBoundCount() {
		rxBoundCount++;
	}

	public synchronized void incTrxBoundCount() {
		trxBoundCount++;
	}

	public synchronized void incBindTransmitterOK() {
		bindTransmitterOK++;
	}

	public synchronized void incBindTransmitterERR() {
		bindTransmitterERR++;
	}

	public synchronized void incBindTransceiverOK() {
		bindTransceiverOK++;
	}

	public synchronized void incBindTransceiverERR() {
		bindTransceiverERR++;
	}

	public synchronized void incBindReceiverOK() {
		bindReceiverOK++;
	}

	public synchronized void incBindReceiverERR() {
		bindReceiverERR++;
	}

	public synchronized void incSubmitSmOK() {
		submitSmOK++;
	}

	public synchronized void incSubmitSmERR() {
		submitSmERR++;
	}

	public synchronized void incSubmitMultiOK() {
		submitMultiOK++;
	}

	public synchronized void incSubmitMultiERR() {
		submitMultiERR++;
	}

	public synchronized void incDeliverSmOK() {
		deliverSmOK++;
	}

	public synchronized void incDeliverSmERR() {
		deliverSmERR++;
	}

	public synchronized void incQuerySmOK() {
		querySmOK++;
	}

	public synchronized void incQuerySmERR() {
		querySmERR++;
	}

	public synchronized void incCancelSmOK() {
		cancelSmOK++;
	}

	public synchronized void incCancelSmERR() {
		cancelSmERR++;
	}

	public synchronized void incReplaceSmOK() {
		replaceSmOK++;
	}

	public synchronized void incReplaceSmERR() {
		replaceSmERR++;
	}

	public synchronized void incDataSmOK() {
		dataSmOK++;
	}

	public synchronized void incDataSmERR() {
		dataSmERR++;
	}

	public synchronized void incEnquireLinkOK() {
		enquireLinkOK++;
	}

	public synchronized void incEnquireLinkERR() {
		enquireLinkERR++;
	}

	public synchronized void incUnbindOK() {
		unbindOK++;
	}

	public synchronized void incUnbindERR() {
		unbindERR++;
	}

	public synchronized void incGenericNakOK() {
		genericNakOK++;
	}

	public synchronized void incGenericNakERR() {
		genericNakERR++;
	}

	/**
	 * @return
	 */
	public synchronized long getBindReceiverERR() {
		return bindReceiverERR;
	}

	/**
	 * @return
	 */
	public synchronized long getBindReceiverOK() {
		return bindReceiverOK;
	}

	/**
	 * @return
	 */
	public synchronized long getBindTransceiverERR() {
		return bindTransceiverERR;
	}

	/**
	 * @return
	 */
	public synchronized long getBindTransceiverOK() {
		return bindTransceiverOK;
	}

	/**
	 * @return
	 */
	public synchronized long getBindTransmitterERR() {
		return bindTransmitterERR;
	}

	/**
	 * @return
	 */
	public synchronized long getBindTransmitterOK() {
		return bindTransmitterOK;
	}

	/**
	 * @return
	 */
	public synchronized long getCancelSmERR() {
		return cancelSmERR;
	}

	/**
	 * @return
	 */
	public synchronized long getCancelSmOK() {
		return cancelSmOK;
	}

	/**
	 * @return
	 */
	public synchronized long getDeliverSmERR() {
		return deliverSmERR;
	}

	/**
	 * @return
	 */
	public synchronized long getDeliverSmOK() {
		return deliverSmOK;
	}

	/**
	 * @return
	 */
	public synchronized long getEnquireLinkERR() {
		return enquireLinkERR;
	}

	/**
	 * @return
	 */
	public synchronized  long getEnquireLinkOK() {
		return enquireLinkOK;
	}

	/**
	 * @return
	 */
	public synchronized  long getGenericNakERR() {
		return genericNakERR;
	}

	/**
	 * @return
	 */
	public synchronized  long getGenericNakOK() {
		return genericNakOK;
	}

	/**
	 * @return
	 */
	public synchronized  long getQuerySmERR() {
		return querySmERR;
	}

	/**
	 * @return
	 */
	public synchronized  long getQuerySmOK() {
		return querySmOK;
	}

	/**
	 * @return
	 */
	public synchronized  long getReplaceSmERR() {
		return replaceSmERR;
	}

	/**
	 * @return
	 */
	public synchronized  long getReplaceSmOK() {
		return replaceSmOK;
	}

	/**
	 * @return
	 */
	public synchronized  long getSubmitMultiERR() {
		return submitMultiERR;
	}

	/**
	 * @return
	 */
	public synchronized  long getSubmitMultiOK() {
		return submitMultiOK;
	}

	/**
	 * @return
	 */
	public synchronized  long getSubmitSmERR() {
		return submitSmERR;
	}

	/**
	 * @return
	 */
	public synchronized  long getSubmitSmOK() {
		return submitSmOK;
	}

	/**
	 * @return
	 */
	public synchronized  long getDataSmERR() {
		return dataSmERR;
	}

	/**
	 * @return
	 */
	public synchronized  long getDataSmOK() {
		return dataSmOK;
	}

	/**
	 * @return
	 */
	public synchronized  long getUnbindERR() {
		return unbindERR;
	}

	/**
	 * @return
	 */
	public synchronized  long getUnbindOK() {
		return unbindOK;
	}

	public synchronized void sent(byte[] pdu) {
		byte[] type = PduUtilities.makeByteArrayFromInt(2, 1);
		callback(pdu, type);
	}

	public synchronized void received(byte[] pdu) {
		byte[] type = PduUtilities.makeByteArrayFromInt(1, 1);
		callback(pdu, type);
	}

	private void callback(byte[] pdu, byte[] type) {
		logger.finest("callback - start of operation");
		if (pdu == null)
			return;
		if (type == null)
			return;
		byte[] result = new byte[pdu.length + 9];
		byte[] id = new byte[4];
		try {
			id = SMPPSim.getCallback_id().getBytes("ASCII");
		} catch (Exception e) {
			;
		}
		byte[] length = PduUtilities.makeByteArrayFromInt(pdu.length + 9, 4);
		System.arraycopy(length, 0, result, 0, 4);
		System.arraycopy(type, 0, result, 4, 1);
		System.arraycopy(id, 0, result, 5, 4);
		System.arraycopy(pdu, 0, result, 9, pdu.length);
		try {
			callback_stream.write(result);
			logger.info("callback - written stream to callback connection");
		} catch (IOException ioe) {
			// assume connection gone
			logger.info("Reconnecting to callback server");
			boolean sentOK = false;
			Object callbackMutex = new Object();
			connectToCallbackServer(callbackMutex);
			try {
				Thread.sleep(500);
			} catch (Exception e) {
			}
			// and send again
			synchronized (callbackMutex) {
				while (!sentOK) {
					try {
						callback_stream.write(result);
						sentOK = true;
					} catch (IOException ioe2) {
						connectToCallbackServer(callbackMutex);
					}
				}
			}
		}
		logger.finest("callback - end of operation");
	}

	public synchronized boolean isCallback_server_online() {
		return callback_server_online;
	}

	public synchronized void setCallback_server_online(
			boolean callback_server_online) {
		this.callback_server_online = callback_server_online;
	}

	public synchronized Socket getCallback() {
		return callback;
	}

	public synchronized void setCallback(Socket callback) {
		this.callback = callback;
	}

	public synchronized OutputStream getCallback_stream() {
		return callback_stream;
	}

	public synchronized void setCallback_stream(
			OutputStream callback_stream) {
		this.callback_stream = callback_stream;
	}

	public synchronized  boolean isOutbind_sent() {
		return outbind_sent;
	}

	public synchronized  void setOutbind_sent(boolean outbind_sent) {
		this.outbind_sent = outbind_sent;
	}

	public synchronized  long getOutbindERR() {
		return outbindERR;
	}

	public synchronized  void setOutbindERR(long outbindERR) {
		this.outbindERR = outbindERR;
	}

	public synchronized  long getOutbindOK() {
		return outbindOK;
	}

	public synchronized  void setOutbindOK(long outbindOK) {
		this.outbindOK = outbindOK;
	}

}