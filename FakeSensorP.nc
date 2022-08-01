/**
 *  Source file for implementation of module Middleware
 *  which provides the main logic for middleware message management
 *
 *  @authors Alfredo Landi, Emanuele Diasco.
 */
 
 
generic module FakeSensorP() {

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
		
		random_number = (call Random.rand16()%10);
		if(random_number>=0 && random_number<=2){
			status = 0;
		}else if(random_number>2 && random_number<=5){
			status = 1;
		}else if(random_number==6){
			status = 3;
		}else if (random_number>=7 && random_number<=9){
			status = 2;
		}
		
		my_data.status = status;	
		my_data.x = call Random.rand16()/100;
		my_data.y = call Random.rand16()/100;
		signal Read.readDone( SUCCESS, my_data );
	}
}
