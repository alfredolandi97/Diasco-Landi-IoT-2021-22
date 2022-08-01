/**
 *  Configuration file for wiring of FakeSensorP module to other common 
 *  components to simulate the behavior of a real sensor
 *
 *  @author Luca Pietro Borsani
 */
 
generic configuration FakeSensorC() {

	provides interface Read<my_data_t>;

} implementation {

	components MainC, RandomC;
	components new DummyFakeSensorP();
	components new TimerMilliC();
	
	//Connects the provided interface
	Read = DummyFakeSensorP;
	
	//Random interface and its initialization	
	DummyFakeSensorP.Random -> RandomC;
	RandomC <- MainC.SoftwareInit;
	
	//Timer interface	
	DummyFakeSensorP.Timer0 -> TimerMilliC;

}
