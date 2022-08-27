/**
 *  Source file for implementation of module Middleware
 *  which provides the main logic for middleware message management
 *
 *  @authors Alfredo Landi, Emanuele Diasco
 */
 
 
generic module DummyFakeSensorP() {

	provides interface Read<my_data_t>;
	
	uses interface Random;
	uses interface Timer<TMilli> as Timer0;

} implementation {
	uint8_t random_number;
	uint8_t status;
	my_data_t my_data;

	//***************** Boot interface ********************//
	command error_t Read.read(){
		call Timer0.startOneShot( 10 );
		return SUCCESS;
	}

	//***************** Timer0 interface ********************//
	event void Timer0.fired() {
		
		my_data.status = 3;
		my_data.x = call Random.rand16()/100;
		my_data.y = call Random.rand16()/100;
		signal Read.readDone( SUCCESS, my_data );
	}
}
