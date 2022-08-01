/**
 *  Source file for implementation of module SmartBraceletsC in which
 *  the node 1 send a request to node 2 until it receives a response.
 *  The reply message contains a reading from the Fake Sensor.
 *
 *  @authors Alfredo Landi, Emanuele Diasco
 */

#include "SmartBracelets.h"
#include "Timer.h"
#include "printf.h"

module SmartBraceletsC {

  uses {
  /****** INTERFACES *****/
	interface Boot; 
	
    //interfaces for communication
    interface SplitControl;
    interface AMSend;
    interface Receive;
    interface Packet;
    interface PacketAcknowledgements;
    
	//interface for timer
	interface Timer<TMilli> as MilliTimer;
	interface Timer<TMilli> as ParentMilliTimer;
	
    //other interfaces, if needed
	
	//interface used to perform sensor reading (to get the value from a sensor)
	interface Read<my_data_t> as Read;
  }

} implementation {


  message_t packet;
  bool alerted=FALSE;
  my_data_t last_received_position;
  uint8_t type;

  void sendReq();
  void sendResp();
  
  
  
  
  //***************** Send request function ********************//
  void sendReq() {
	/* This function is called when we want to send a request
	 *
	 * STEPS:
	 * 1. Prepare the msg
	 * 2. Set the ACK flag for the message using the PacketAcknowledgements interface
	 *     (read the docs)
	 * 3. Send an UNICAST message to the correct node
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 my_msg_t *mess = (my_msg_t*)(call Packet.getPayload(&packet, sizeof(my_msg_t)));
	  if (mess == NULL) {
		return;
	  }
	  mess->msg_type = PARENT_REQ;
	  
	  
	  if(call PacketAcknowledgements.requestAck(&packet)==SUCCESS){
	  		//TOSSIM
	  		dbg("radio_ack", "Acknowledgements are enabled\n");
	  		
	  		//COOJA
	  		printf("Acknowledgements are enabled\n");
	  }else{
	  		//TOSSIM
	  		dbg("radio_ack", "Error in requesting ACKs to other mote\n");
	  		
	  		//COOJA
	  		printf("Error in requesting ACKs to other mote\n");
	  }
	  //TOSSIM
	  dbg("radio_pack","Preparing the request... \n");
	  
	  //COOJA
	  printf("Preparing the request... \n");
	  
	  if(call AMSend.send(2, &packet,sizeof(my_msg_t)) == SUCCESS){
	  
	     //TOSSIM
	     dbg_clear("radio_pack","Starting packet sending\n" );
		 dbg_clear("radio_pack","type: %hhu \n ", mess->msg_type);
		 
		 //COOJA
		 printf("Starting packet sending\n" );
		 printf("type: %hhu \n ", mess->msg_type);
		 
		 
  	}
	 
 }        

  //****************** Task send response *****************//
  void sendResp() {
  	/* This function is called when we receive the REQ message.
  	 * Nothing to do here. 
  	 * `call Read.read()` reads from the fake sensor.
  	 * When the reading is done it raises the event read done.
  	 */
	call Read.read();
  }

  //***************** Boot interface ********************//
  event void Boot.booted() {
  
  	//TOSSIM
	dbg("boot","Application booted\n");
	
	//COOJA
	printf("Application booted\n");
	
	call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
  
  event void SplitControl.startDone(error_t err){
    
    if(err == SUCCESS) {
    	//TOSSIM
    	dbg("radio", "Split Control Start DONE!\n");
    	
    	//COOJA
    	printf("Split Control Start DONE!\n");
		if (TOS_NODE_ID % 2 == 0){
		 	printf("STARTING CHILD\n");
           call MilliTimer.startPeriodic( 10000 );
  		}
    }else{
	//dbg for error
	call SplitControl.start();
    }

    
  }
  
  
  event void SplitControl.stopDone(error_t err){
  
    //TOSSIM
    dbg("role", "End of execution\n");
    
    //COOJA
    printf("End of execution\n");
  }

  //***************** MilliTimer interface ********************//
  
  event void MilliTimer.fired() {
	/* This event is triggered every time the timer fires.
	 * When the timer fires, we send a request
	 */
	 sendResp();
	 
  }
  

  //********************* AMSend interface ****************//
  
  event void AMSend.sendDone(message_t* buf,error_t err) {
	/* This event is triggered when a message is sent 
	 *
	 * STEPS:
	 * 1. Check if the packet is sent
	 * 2. Check if the ACK is received (read the docs)
	 * 2a. If yes, stop the timer according to your id. The program is done
	 * 2b. Otherwise, send again the request
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 if (&packet == buf && err == SUCCESS) {
	 //TOSSIM
      dbg("radio_send", "Packet sent\n");
      
      //COOJA
       printf("Packet sent\n");
       
    }else{
    
      //TOSSIM
      dbgerror("radio_send", "Send done error!\n");
      
      //COOJA
      printf("Send done error!\n");
    }
    if(call PacketAcknowledgements.wasAcked(&packet) == TRUE){
    
    	//TOSSIM
    	dbg("radio_ack", "ACK recieved\n");
    	
    	//COOJA
    	printf("ACK recieved\n");
    	
    }else{
    
    	//TOSSIM
    	dbg("radio_ack", "ACK not recieved\n");
    	
    	//CO0JA
    	printf("ACK not recieved\n");
    	
    }
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	/* This event is triggered when a message is received 
	 *
	 * STEPS:
	 * 1. Read the content of the message
	 * 2. Check if the type is request (REQ)
	 * 3. If a request is received, send the response
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	if (len != sizeof(my_msg_t)) {
		return buf;
	}
    else {
      my_msg_t* mess = (my_msg_t*)payload;
      
      if(mess->msg_type==PARENT_REQ){ 
      
	  	//TOSSIM
	  	dbg("radio_rec", "Message Received from the Parent at time %s\n", sim_time_string());
	  	dbg_clear("radio_pack", "I'm Child n° %d\n", TOS_NODE_ID);
	  	
	  	//COOJA
	  	printf("Message Received from the Parent\n");
	  	printf("I'm Child n° %d\n", TOS_NODE_ID);
	  	
	  }else if(mess->msg_type==CHILD_RESP){  
	  
	  		//TOSSIM
	  		dbg("radio_pack","Message Received from the Child at time %s\n", sim_time_string());
      		dbg_clear("radio_pack", "I'm Parent n° %d\n", TOS_NODE_ID);
	  		dbg_clear("radio_pack", "x-coordinate: %hhu \n ", mess->my_data.x);
	  		dbg_clear("radio_pack", "y-coordinate: %hhu \n ", mess->my_data.y);
	  		dbg_clear("radio_pack", "status: %hhu \n ", mess->my_data.status);
	  		
	  		//COOJA
	  		printf("Message Received from the Child\n");
      		printf("I'm Parent n° %d\n", TOS_NODE_ID);
	  		printf("x-coordinate: %hhu \n ", mess->my_data.x);
	  		printf("y-coordinate: %hhu \n ", mess->my_data.y);
	  		printf("status: %hhu \n ", mess->my_data.status);
	  		
	  	if(alerted == FALSE){
	  	
	  		//TOSSIM
	  		dbg("radio_pack","Alerted is False\n");
      		
	  		
	  		//COOJA
	  		printf("Alerted is FALSE\n");
	  		
	  		
	  		//3 IS FALLING STATE 
	  		if(mess->my_data.status == 3){
	  		
	  		    //TOSSIM
	  			dbg("debug","Falling State Recieved\n");
	  			
	  			//COOJA
	  			printf("Falling State Recieved\n");
	  			
	  			call ParentMilliTimer.startPeriodic(60000);
	  			last_received_position.x=mess->my_data.x;
	  			last_received_position.y=mess->my_data.y;
	  			last_received_position.status=mess->my_data.status;
	  			type=mess->msg_type;
	  			alerted=TRUE;
	  		}
	  	}else if(alerted==TRUE){
	  		
	  		//TOSSIM
	  		dbg("radio_pack","Alerted is TRUE\n");
      		
	  		
	  		//COOJA
	  		printf("Alerted is TRUE\n");
	  		
	  		if (mess->my_data.status==3){
	  		
	  			//TOSSIM
	  			dbg("debug","Another consecutive Falling state received\n");
	  			dbg("debug","STOPPING TIMER\n");
	  			
	  			//COOJA
	  			printf("Another consecutive Falling state received\n");
	  			printf("STOPPING TIMER\n");
	  			
	  			call ParentMilliTimer.stop();
	  			
	  			//TOSSIM
	  			dbg("debug","RESTARTING TIMER\n");
	  			
	  			//COOJA
	  			printf("RESTARTING TIMER \n");
	  			
	  			call ParentMilliTimer.startPeriodic(60000);
	  			last_received_position.x=mess->my_data.x;
	  			last_received_position.y=mess->my_data.y;
	  			last_received_position.status=mess->my_data.status;
	  			type=mess->msg_type;
	  			
			}else{
			
				//TOSSIM
				dbg("debug","Update received,NO-MORE EMERGENCY\n");
				
				//COOJA
				printf("Update received,NO-MORE EMERGENCY\n");
				
				alerted=FALSE;
				call ParentMilliTimer.stop();
			}
			
	  	}
	  	sendReq();
	  }
      return buf;
    }
    {
      //TOSSIM	
      dbgerror("radio_rec", "Receiving error \n");
      
      //COOJA
      printf("Receiving error \n");
      
    }
  }
  
  //************************* Read interface **********************//
  event void Read.readDone(error_t result, my_data_t data) {
	/* This event is triggered when the fake sensor finishes to read (after a Read.read()) 
	 *
	 * STEPS:
	 * 1. Prepare the response (RESP)
	 * 2. Send back (with a unicast message) the response
	 * X. Use debug statement showing what's happening (i.e. message fields)
	 */
	 my_msg_t* mess = (my_msg_t*)(call Packet.getPayload(&packet, sizeof(my_msg_t)));
	  if (mess == NULL) {
		return;
	  }
	  
	  mess->msg_type = CHILD_RESP;
	  mess->my_data = data;
	  
	  if(call PacketAcknowledgements.requestAck(&packet)==SUCCESS){
	  
	  		//TOSSIM
	  		dbg("radio_ack", "Acknowledgements are enabled\n");
	  		
	  		//COOJA
	  		printf("Acknowledgements are enabled\n");
	  }else{
	  		//TOSSIM
	  		dbg("radio_ack", "Error in requesting ACKs to other mote\n");
	  		
	  		//COOJA
	  		printf("Error in requesting ACKs to other mote\n");
	  }
	  
	  if(call AMSend.send(1, &packet,sizeof(my_msg_t)) == SUCCESS){
	  
	  	//TOSSIM
	  	dbg_clear("radio_pack", "Reading data from Fake Sensor \n");
	  	dbg_clear("radio_pack", "\t\t x-coordinate: %hhu \n ", mess->my_data.x);
	  	dbg_clear("radio_pack", "\t\t y-coordinate: %hhu \n ", mess->my_data.y);
	  	dbg_clear("radio_pack", "\t\t status: %hhu \n ", mess->my_data.status);
	  	
	  	//COOJA
	  	printf("Reading data from Fake Sensor \n");
	  	printf("x-coordinate: %hhu \n ", mess->my_data.x);
	  	printf("y-coordinate: %hhu \n ", mess->my_data.y);
	  	printf("status: %hhu \n ", mess->my_data.status);
	  	
		}

	}
	/* This timer is fired when the child doesn't send any response to the Parent after 60 seconds from the last 
	*  falling state received. 
	*/
	event void ParentMilliTimer.fired(){
	
		//TOSSIM
		dbg("radio_pack","No more response received after the last FALLING state... \n");
      	dbg("radio_pack", ">>>Last position received: \n");
	  	dbg_clear("radio_pack", "\t\t x-coordinate: %hhu \n ", last_received_position.x);
	  	dbg_clear("radio_pack", "\t\t y-coordinate: %hhu \n ", last_received_position.y);
	    dbg_clear("radio_pack", "\t\t MISSING ALARM \n ");
	    
	    //COOJA
	    printf("No more response received after the last FALLING state...\n");
      	printf(">>>Last position received: \n");
	  	printf("x-coordinate: %hhu \n ", last_received_position.x);
	  	printf("y-coordinate: %hhu \n ", last_received_position.y);
	    printf("MISSING ALARM \n ");
	    
	  	call ParentMilliTimer.stop();
	}
}

