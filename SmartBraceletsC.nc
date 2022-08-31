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
	interface Timer<TMilli> as ChildMilliTimer;
	interface Timer<TMilli> as ParentMilliTimer;
	
	//interface used to perform sensor reading (to get the value from a sensor)
	interface Read<my_data_t> as Read;
  }

} implementation {
  message_t packet;
  uint64_t mykey;
  
  /* Pairing phases
   * 0-> Broadcasting phase.
   * 1-> Special message phase
   * 2-> Paired phase
  */
  uint8_t paired=0;
  uint8_t coupled=0;
  bool sentSpecialMessage=FALSE;
  bool alerted=FALSE;
  my_data_t last_received_position;
  uint8_t type;

  
  void sendBroadcastMessage();
  void sendSpecialMessage();
  void sendChildResp();
  
  //****************** Task send Broadcast Message *****************//
  void sendBroadcastMessage(){
  		/*sendBroadcastMessage is called at the very beginning of our execution,
  		 *when every single mote has to discover which other mote owns the same key
  		 *as itself
  		 */
  		my_msg_t *mess = (my_msg_t*)(call Packet.getPayload(&packet, sizeof(my_msg_t)));
	 	if (mess == NULL) {
		  return;
	 	}
	 	
	 	//TOSSIM
	  	dbg("radio_pack","Preparing the broadcast message...\n");
	  	
	 	//COOJA
	  	printf("Preparing the broadcast message...\n");
	  	
	  	
	  	mess->my_tos_node_id=TOS_NODE_ID;
	  	mess->my_key=mykey;
	  	mess->special_code=0;
	  	
	  	
	    if(call AMSend.send(AM_BROADCAST_ADDR, &packet,sizeof(my_msg_t)) == SUCCESS){
	 		//COOJA
		 	printf(">>>Sending broadcast message...\n");
	    	printf("my_tos_node_id: %d\n", mess->my_tos_node_id);
		 	printf("my_key: %llu\n", mess->my_key);   		 
  		}
  	}
  	
  	//****************** Task send Special Message *****************//
  	void sendSpecialMessage(){
  		/*After a mote has found the other mote which has its own key, it has to send a special message,
  		 *1 in our convention, and we use this method to allow this behavior
  		 */
  		my_msg_t *mess = (my_msg_t*)(call Packet.getPayload(&packet, sizeof(my_msg_t)));
	  	if (mess == NULL) {
			return;
	  	}
	  	
	  	if(call PacketAcknowledgements.requestAck(&packet)==SUCCESS){
	  		//COOJA
	  		printf("Acknowledgements are enabled\n");
	  	}else{
	  		//COOJA
	  		printf("Error in requesting ACKs to other mote\n");
	  	}
	  	
	  	//COOJA
	  	printf("Preparing the special message...\n");
	  	
	  	mess->special_code=1;
	  	mess->my_data_not_yet_readable=TRUE;
	  
	  	if(call AMSend.send(coupled, &packet,sizeof(my_msg_t)) == SUCCESS){
		 	//COOJA
		 	printf(">>>Sending special message...\n");
			printf("Special code: %d\n", mess->special_code);
  		}		
  	}
  

  //****************** Task send Child Response *****************//
  void sendChildResp() {
  	/* This function is called when the ChildMilliTimer is fired, i.e. every 10 seconds. 
  	 * `call Read.read()` reads from the fake sensor.
  	 * When the reading is done it raises the event read done.
  	 */
	call Read.read();
  }

  //***************** Boot interface ********************//
  event void Boot.booted() {
	//COOJA
	printf("Application booted\n");
	
	call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
  /*According to different TOS_NODE_ID assign preloaded key to motes, the rules are the following:
   *the two couples are TOS_NODE_ID (1, 2) and (3, 4), children are always identified by an even
   *TOS_NODE_ID (in our simulation 2 and 4)
   */ 
    if(err == SUCCESS) {
    	//COOJA
    	printf("Split Control Start DONE!\n");
    	
		if (TOS_NODE_ID == 1){
			//COOJA
		 	printf("STARTING PARENT no.%d\n", TOS_NODE_ID);
		 	mykey=17263987259413674582;
		 	
  		}else if(TOS_NODE_ID == 2){  			
  			//COOJA
  			printf("STARTING CHILD no.%d\n", TOS_NODE_ID);
  			mykey=17263987259413674582;
  			
  		}else if(TOS_NODE_ID == 3){			
			//COOJA
		 	printf("STARTING PARENT no.%d\n", TOS_NODE_ID);
  			mykey=13945678216985476321;
  			
  		}else if(TOS_NODE_ID == 4){
  			//COOJA
  			printf("STARTING CHILD no.%d\n", TOS_NODE_ID);
			mykey=13945678216985476321;
			
  		}
  		sendBroadcastMessage();
  		
    }else{
	//dbg for error
	call SplitControl.start();
    }
  }
  
  event void SplitControl.stopDone(error_t err){
    //COOJA
    printf("End of execution\n");
  }

  //***************** ChildMilliTimer interface ********************//
  event void ChildMilliTimer.fired() {
	/* This event is triggered every time the timer fires.
	 * When the timer fires, we send a childResp with coordinates and status of child's bracelet
	 */
	 sendChildResp();
  }
  

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {
	/*This event is triggered when a message is sent.
	 *Every time a message is sent in a specific pairing phase and its own ack is received,
	 *we allow the program to go to the next step of the pairing execution, till we reach
	 *paired equal to 2, which represents the step where the connection is perfectly set up and
	 *the mote has to receive only coordinates or ACKs according to its type (parent or child)
	 */
	 if (&packet == buf && err == SUCCESS) {
       //COOJA
       printf("Packet sent\n");
       
    }else{      
      //COOJA
      printf("Send done error!\n");
    }
     if(paired==0){
     	if(coupled!=0){
      		paired=1;
      		printf("Broadcasting phase completed\n");
      		sendSpecialMessage();
      	}
      }else{
      	if(call PacketAcknowledgements.wasAcked(&packet) == TRUE){
    		//COOJA
    		printf("ACK recieved\n");
    		if(paired==1){
    			sendSpecialMessage();
    			sentSpecialMessage=TRUE;
    		}
    	}else{
    		//CO0JA
    		printf("ACK not recieved\n");
    		if(paired==1){
    			sendSpecialMessage();
    		}
    	}
      }
  	}

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	/* This event is triggered when a message is received.
	 * When paired is set to 0 we need to receive a broadcast message, then when paired
	 * becomes 1 we expect a special message, which in our convention is a 1, finally
	 * paired equal to 2 shows that we are able to receive coordinates and statuses,
	 * if we are in a parent execution, or ACKs from the parent if the code is running
	 * in a child
	 */
	if (len != sizeof(my_msg_t)) {
		return buf;
	}
    else {
      my_msg_t* mess = (my_msg_t*)payload;
      
      if(paired==0){
      	if(mess->my_key == mykey){
			coupled= mess-> my_tos_node_id;
      	}
      	sendBroadcastMessage();      
      }else if(paired==1){
      	if(mess->special_code==1 && sentSpecialMessage==TRUE){
      		paired=2;
      		printf("Special message phase completed\n");
      		if(TOS_NODE_ID%2==0){
    			printf("Starting ChildMilliTimer for mote %d\n", TOS_NODE_ID);	
      			call ChildMilliTimer.startPeriodic( 10000 );
    		}else{
    		}
      	}else{
    		sendSpecialMessage();
    	}
      }else if(paired==2){
      		if(TOS_NODE_ID%2!=0 && mess->my_tos_node_id==coupled && mess->my_data_not_yet_readable==FALSE){
      			printf(">>>INFO message received from child mote:\n");
	  			printf("(x, y) -> (%d, %d)\n", mess->my_data.x, mess->my_data.y);
	  			if(mess->my_data.status == 0){
	  				printf("Status: STANDING\n");
	  			}else if(mess->my_data.status == 1){
	  				printf("Status: WALKING\n");
	  			}else if(mess->my_data.status == 2){
	  				printf("Status: RUNNING\n");
	  			}else if(mess->my_data.status == 3){
	  				printf("Status: FALLING\n");
	  			}
	  			
	  			call ParentMilliTimer.startOneShot(60000);
	  			last_received_position.x=mess->my_data.x;
	  			last_received_position.y=mess->my_data.y;
	  	    	
      		}
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
	 */
	 my_msg_t* mess = (my_msg_t*)(call Packet.getPayload(&packet, sizeof(my_msg_t)));
	  if (mess == NULL) {
		return;
	  }
	  
	  mess->my_data = data;
	  mess->my_data_not_yet_readable = FALSE;
	  
	  	if(call PacketAcknowledgements.requestAck(&packet)==SUCCESS){	  		
	  		//COOJA
	  		printf("Acknowledgements are enabled\n");
	  	}else{
	  		//COOJA
	  		printf("Error in requesting ACKs to other mote\n");
	  	}
	  
	  
	  	if(call AMSend.send(coupled, &packet,sizeof(my_msg_t)) == SUCCESS){	
	  		//COOJA
	  		printf(">>>Reading data from Fake Sensor...\n");
	  		printf("(x, y) -> (%d, %d)\n", mess->my_data.x, mess->my_data.y);
	  		if(mess->my_data.status == 0){
	  				printf("Status: STANDING\n");
	  			}else if(mess->my_data.status == 1){
	  				printf("Status: WALKING\n");
	  			}else if(mess->my_data.status == 2){
	  				printf("Status: RUNNING\n");
	  			}else if(mess->my_data.status == 3){
	  				printf("Status: FALLING\n");
	  			}
		}
	  
	  
	}
	
	//***************** ParentMilliTimer interface ********************//
	event void ParentMilliTimer.fired(){
		/*  This timer is fired when the child doesn't send any response to the Parent after 60 seconds from the last 
		*  falling state received. 
		*/
	    //COOJA
	    printf("No more INFO messages received after 1 minute...\n");
      	printf(">>>Last position received: \n");
	  	printf("(x, y) -> (%d, %d)\n", last_received_position.x, last_received_position.y);
	    printf("MISSING ALARM\n");
	    
	  	call ParentMilliTimer.stop();
	}
}

