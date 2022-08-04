/**
 *  Configuration file for wiring of SmartBraceletsC module to other common 
 *  components needed for proper functioning
 *
 *  @authors Alfredo Landi, Emanuele Diasco
 */

#include "SmartBracelets.h"
<<<<<<< Updated upstream
#define NEW_PRINTF_SEMANTICS
#include "printf.h"
=======

//#define TOSSIM

#ifndef TOSSIM
	#define NEW_PRINTF_SEMANTICS
	#include "printf.h"
#endif
>>>>>>> Stashed changes

configuration SmartBraceletsAppC {}

implementation {


  /****** COMPONENTS *****/
  components MainC, SmartBraceletsC as App;
  components new TimerMilliC() as t;
  components new TimerMilliC() as t2;
  components new FakeSensorC();
  components ActiveMessageC;
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);
  components SerialPrintfC;
  components SerialStartC;
  

  /****** INTERFACES *****/
  //Boot interface
  App.Boot -> MainC.Boot;

  //Send and Receive interfaces
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  
  //Radio Control
  App.SplitControl -> ActiveMessageC;
  
  //Interfaces to access package fields
  App.Packet -> AMSenderC;
  
  //Timer interface
  App.ChildMilliTimer -> t;
  App.ParentMilliTimer -> t2;
  
  //Fake Sensor read
  App.Read -> FakeSensorC.Read;
  
  //Interfaces to communicate
  App.PacketAcknowledgements -> ActiveMessageC;
}

