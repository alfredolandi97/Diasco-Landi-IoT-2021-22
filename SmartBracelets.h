

#ifndef SMARTBRACELETS_H
#define SMARTBRACELETS_H


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

//payload of the msg
typedef nx_struct bracelets_msg {
	nx_uint8_t my_tos_node_id;
	nx_uint64_t my_key;
	nx_uint8_t special_code;
	nx_uint8_t msg_type;
	my_data_t my_data;
} my_msg_t;

#define PARENT_REQ 1
#define CHILD_RESP 2



enum{
	AM_MY_MSG = 6,
};

#endif
