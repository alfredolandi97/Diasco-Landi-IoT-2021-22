/**
 *  Configuration file for wiring of FakeSensorP module to other common 
 *  components to simulate the behavior of a real sensor
 *
 *  @authors Alfredo Landi, Emanuele Diasco.
 */
 
generic configuration FakeSensorC() {

	provides interface Read<my_data_t>;

} implementation {

	components MainC, RandomC;
	//components new DummyFakeSensorP();
	components new FakeSensorP();
	components new TimerMilliC();
	
	//Connects the provided interface
	Read = FakeSensorP;
	//Read = DummyFakeSensorP;
	
	//Random interface and its initialization	
	FakeSensorP.Random -> RandomC;
	//DummyFakeSensorP.Random -> RandomC;
	RandomC <- MainC.SoftwareInit;
	
	//Timer interface	
	FakeSensorP.Timer0 -> TimerMilliC;
	//DummyFakeSensorP.Timer0 -> TimerMilliC;

}
