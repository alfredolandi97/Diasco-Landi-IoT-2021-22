/**
 *  Configuration file for wiring of SmartBraceletsC module to other common 
 *  components needed for proper functioning
 *
 *  @authors Alfredo Landi, Emanuele Diasco
 */

#include "SmartBracelets.h"
#define NEW_PRINTF_SEMANTICS
#include "printf.h"

configuration SmartBraceletsAppC {}

implementation {


  /****** COMPONENTS *****/
  components MainC, SmartBraceletsC as App;
  //add the other components here
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

  /****** Wire the other interfaces down here *****/
  //Send and Receive interfaces
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  
  //Radio Control
  App.SplitControl -> ActiveMessageC;
  
  //Interfaces to access package fields
  App.Packet -> AMSenderC;
  
  //Timer interface
  App.MilliTimer -> t;
  App.ParentMilliTimer -> t2;
  
  //Fake Sensor read
  App.Read -> FakeSensorC.Read;
  
  //Interfaces to communicate
  App.PacketAcknowledgements -> ActiveMessageC;

}

