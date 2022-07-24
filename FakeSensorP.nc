/**
 *  Source file for implementation of module Middleware
 *  which provides the main logic for middleware message management
 *
 *  @author Luca Pietro Borsani
 */
 
 #include <SmartBracelets.h>
 
generic module FakeSensorP() {

	provides interface Read<uint16_t>;
	
	uses interface Random;
	uses interface Timer<TMilli> as Timer0;

} implementation {
	my_data_t my_data;
	uint8_t random_number;
	uint8_t status;

	//***************** Boot interface ********************//
	command error_t Read.read(){
		call Timer0.startOneShot( 10 );
		return SUCCESS;
	}

	//***************** Timer0 interface ********************//
	event void Timer0.fired() {
		
		random_number = (call Random.rand16)%10;
		if(random_number<=2){
			status = 0;
		}else if(random_number>2 && random_number<=5){
			status = 1;
		}else if(random_number>5 && random_number<=8){
			status = 2;
		}else{
			status = 3;
		}
		
		my_data.status = status;	
		my_data.x = call Random.rand16();
		my_data.y = call Random.rand16();
		signal Read.readDone( SUCCESS, my_data );
	}
}
