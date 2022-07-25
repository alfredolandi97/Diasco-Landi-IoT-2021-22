

#ifndef SMARTBRACELETS_H
#define SMARTBRACELETS_H


/*
* Table of statuses
* 0 -> STANDING
* 1 -> WALKING
* 2 -> RUNNING
* 3 -> FALLING
*/

typedef struct my_data {
	uint8_t status;
	uint16_t x;
	uint16_t y;
} my_data_t;

//payload of the msg
typedef nx_struct bracelets_msg {
	nx_uint8_t msg_type;
	my_data_t my_data;
} my_msg_t;

#define REQ 1
#define RESP 2

enum{
	AM_MY_MSG = 6,
};

#endif
