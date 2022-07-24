/**
 *  @author Luca Pietro Borsani
 */

#ifndef SENDACK_H
#define SENDACK_H

//payload of the msg
typedef nx_struct my_msg {
	nx_uint8_t msg_type;
	nx_uint8_t msg_counter;
	nx_uint16_t value;
} my_msg_t;

/*
* Table of statuses
* 0 -> STANDING
* 1 -> WALKING
* 2 -> RUNNING
* 3 -> FALLING
*/
typedef nx_struct my_data {
	nx_uint8_t status;
	nx_uint16_t x;
	nx_uint16_t y;
} my_data_t;

#define REQ 1
#define RESP 2 

enum{
	AM_MY_MSG = 6,
};

#endif
