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
	  		
	  		//TOSSIM
	     	dbg_clear("radio_pack","Starting broadcasting phase\n");
	     	dbg_clear("radio_pack","my_tos_node_id: %d\n", mess->my_tos_node_id);
		 	dbg_clear("radio_pack","my_key: %llu\n", mess->my_key);
		 	dbg_clear("radio_pack","special_code: %d\n", mess->special_code);
	
	 		//COOJA
		 	printf("Starting broadcasting phase\n");
	    	printf("my_tos_node_id: %d\n", mess->my_tos_node_id);
		 	printf("my_key: %llu\n", mess->my_key);
		 	printf("special code: %d\n", mess->special_code);    		 
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
	  	dbg("radio_pack","Preparing the special message...\n");
	  	
	  	//COOJA
	  	printf("Preparing the special message...\n");
	  	
	  	mess->special_code=1;
	  	mess->my_data_not_yet_readable=TRUE;
	  
	  	if(call AMSend.send(coupled, &packet,sizeof(my_msg_t)) == SUCCESS){
	     	//TOSSIM
	    	dbg_clear("radio_pack","Starting sending special message\n");
			dbg_clear("radio_pack","Special code: %d\n", mess->special_code);
			
		 	//COOJA
		 	printf("Starting sending special message\n");
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
  
  	//TOSSIM
	dbg("boot","Application booted\n");
	
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
    	//TOSSIM
    	dbg("radio", "Split Control Start DONE!\n");
    	
    	//COOJA
    	printf("Split Control Start DONE!\n");
    	
		if (TOS_NODE_ID == 1){
			//TOSSIM
			dbg("radio", "Starting parent no.%d\n", TOS_NODE_ID);
			
			//COOJA
		 	printf("STARTING PARENT no.%d\n", TOS_NODE_ID);
		 	mykey=17263987259413674582;
		 	
  		}else if(TOS_NODE_ID == 2){
  			//TOSSIM
  			dbg("radio", "Starting child no.%d", TOS_NODE_ID);
  			
  			//COOJA
  			printf("STARTING CHILD no.%d\n", TOS_NODE_ID);
  			mykey=17263987259413674582;
  			
  		}else if(TOS_NODE_ID == 3){
  			//TOSSIM
			dbg("radio", "Starting parent no.%d\n", TOS_NODE_ID);
			
			//COOJA
		 	printf("STARTING PARENT no.%d\n", TOS_NODE_ID);
  			mykey=13945678216985476321;
  			
  		}else if(TOS_NODE_ID == 4){
  			//TOSSIM
  			dbg("radio", "Starting child no.%d", TOS_NODE_ID);
  			
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
    //TOSSIM
    dbg("role", "End of execution\n");
    
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
     if(paired==0){
     	printf("paired = 0, sent a Broadcast Message\n");
     	if(coupled!=0){
     		printf("I already know my coupled device, setting paired = 1 and sending a special message\n");
      		paired=1;
      		sendSpecialMessage();
      	}else{
      		sendBroadcastMessage();
      	}
      }else{
      	if(call PacketAcknowledgements.wasAcked(&packet) == TRUE){
    		//TOSSIM
    		dbg("radio_ack", "ACK recieved\n");
    		
    		//COOJA
    		printf("ACK recieved\n");
    		if(paired==1){
    			printf("paired = 1 in sendDone, I sent my special message\n");
    			sendSpecialMessage();
    			sentSpecialMessage=TRUE;
    		}
    	}else{
    		//TOSSIM
    		dbg("radio_ack", "ACK not recieved\n");
    		
    		//CO0JA
    		printf("ACK not recieved\n");
    		if(paired==1){
    			printf("Sending again Broadcast Message\n");
    			sendBroadcastMessage();
    			printf("Sending again Special Message\n");
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
      	//Cooja
      	printf("Paired = 0, receiving a broadcast message\n");
      	if(mess->my_key == mykey){
			coupled= mess-> my_tos_node_id;
			mykey=0;
			printf("The broadcast message contains my same key\n");
      	}else{
      		sendBroadcastMessage();
      		printf("Sending again a Broadcast message\n");
      	}      
      }else if(paired==1){
      	printf("Paired = 1, receiving a Special Message\n");
      	if(mess->my_key==0){
      		if(mess->special_code==1 && sentSpecialMessage==TRUE){
      		 printf("I both sent and received a Special Message, setting paired = 2\n");
      		 paired=2;
      		 if(TOS_NODE_ID%2==0){
    			printf("Starting ChildMilliTimer for mote %d\n", TOS_NODE_ID);	
      			call ChildMilliTimer.startPeriodic( 10000 );
    		 }
      	   }else{
    		sendSpecialMessage();
    	   }
      	}else{
      		sendBroadcastMessage();
      	}
      }else if(paired==2){
      		if(TOS_NODE_ID%2!=0 && mess->my_tos_node_id==coupled && mess->my_data_not_yet_readable==FALSE){
      			//TOSSIM
	  			dbg("radio_pack","Message Received from the Child at time %s\n", sim_time_string());
      			dbg_clear("radio_pack", "I'm Parent no. %d\n", TOS_NODE_ID);
	  			dbg_clear("radio_pack", "Received x-coordinate: %d\n", mess->my_data.x);
	  			dbg_clear("radio_pack", "Received y-coordinate: %d\n", mess->my_data.y);
	  			dbg_clear("radio_pack", "Received status: %d\n", mess->my_data.status);
	  		
	  			//COOJA
	  			printf("Message Received from the Child no. %d\n", coupled);
      			printf("I'm Parent no. %d\n", TOS_NODE_ID);
      			//Debug beginning
      			printf("Value of my_data struct: %p\n", &mess->my_data);
      			printf("Owner's tos_node_id: %d\n", mess->my_tos_node_id);
      			printf("Key message: %llu\n", mess->my_key);
	  			printf("Special code: %d\n", mess->special_code);
	  			//Debug ending
	  			printf("Received x-coordinate: %d\n", mess->my_data.x);
	  			printf("Received y-coordinate: %d\n", mess->my_data.y);
	  			printf("Received status: %d\n", mess->my_data.status);
	  		
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
	  			
					}else{
						//TOSSIM
						dbg("debug","Update received,NO-MORE EMERGENCY\n");
					
						//COOJA
						printf("Update received,NO-MORE EMERGENCY\n");
					
						alerted=FALSE;
						call ParentMilliTimer.stop();
					}
	  			}
      		}else{
      			printf("I'm mote %d, received a Message not expected\n", TOS_NODE_ID);
	  			printf("Printing its content...\n");
      			printf("Owner's tos_node_id: %d\n", mess->my_tos_node_id);
      			printf("Key message: %llu\n", mess->my_key);
	  			printf("Special code: %d\n", mess->special_code);
	  			printf("Value of my_data struct: %p\n", &mess->my_data);
	  			printf("x-coordinate: %d\n", mess->my_data.x);
	  			printf("y-coordinate: %d\n", mess->my_data.y);
	  			printf("status: %d\n", mess->my_data.status);
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
	  
	  
	  	if(call AMSend.send(coupled, &packet,sizeof(my_msg_t)) == SUCCESS){
	  		//TOSSIM
	  		dbg_clear("radio_pack", "I'm the child no. %d\n", TOS_NODE_ID);
	  		dbg_clear("radio_pack", "I'm sending to parent no. %d\n", coupled);
	  		dbg_clear("radio_pack", "Reading data from Fake Sensor \n");
	  		dbg_clear("radio_pack", "\t\t read x-coordinate: %d\n", mess->my_data.x);
	  		dbg_clear("radio_pack", "\t\t read y-coordinate: %d\n", mess->my_data.y);
	  		dbg_clear("radio_pack", "\t\t read status: %d\n", mess->my_data.status);
	  			
	  		//COOJA
	  		printf("I'm the child no. %d\n", TOS_NODE_ID);
	  		printf("I'm sending to parent no. %d\n", coupled);
	  		printf("Reading data from Fake Sensor \n");
	  		printf("Read x-coordinate: %d\n", mess->my_data.x);
	  		printf("Read y-coordinate: %d\n", mess->my_data.y);
	  		printf("Read status: %d\n", mess->my_data.status);
		}
	  
	  
	}
	
	//***************** ParentMilliTimer interface ********************//
	event void ParentMilliTimer.fired(){
		/*  This timer is fired when the child doesn't send any response to the Parent after 60 seconds from the last 
		*  falling state received. 
		*/
		
		//TOSSIM
		dbg("radio_pack","No more response received after the last FALLING state... \n");
      	dbg("radio_pack", ">>>Last position received: \n");
	  	dbg_clear("radio_pack", "\t\t x-coordinate: %d\n", last_received_position.x);
	  	dbg_clear("radio_pack", "\t\t y-coordinate: %d\n", last_received_position.y);
	    dbg_clear("radio_pack", "\t\t MISSING ALARM \n");
	    	
	    //COOJA
	    printf("No more response received after the last FALLING state...\n");
      	printf(">>>Last position received: \n");
	  	printf("x-coordinate: %d\n", last_received_position.x);
	  	printf("y-coordinate: %d\n", last_received_position.y);
	    printf("MISSING ALARM \n");
	    
	  	call ParentMilliTimer.stop();
	}
}

