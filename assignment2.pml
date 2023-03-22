/**
 * Elevator template model for Assignment 2 of 2IX20 - Software Specification.
 * Set up for one elevator and two floors.
 */

// LTL formulas to be verified
//ltl p1 { []<> (floor_request_made[0]==true) } /* this property does not hold, as a request for floor 1 can be indefinitely postponed. */
//ltl p2 { []<> (cabin_door_is_open==true) } /* this property should hold, but does not yet; at any moment during an execution, the opening of the cabin door will happen at some later point. */
//ltl a1 { [](floor_request_made[0] -> <>current_floor == 0)}
ltl a2 { [](floor_request_made[1] -> <>current_floor == 1)}
//ltl b1 { []<>(cabin_door_is_open == true)}
//ltl b2 { []<>(cabin_door_is_open == false)}
//ltl c  { [](cabin_door_is_open == true -> floor_door_is_open[current_floor] == true)}

//-------------------------------------------------------------------------------------------------
/** the number of floors */
#define NUMBER_OF_FLOORS 2

/** IDs of request button processes */
#define REQUEST_BUTTON_ID (_pid - 4)

//-------------------------------------------------------------------------------------------------
/**
 * this property does not hold, as a request for floor 1 can be indefinitely postponed.
 *
 * TODO uncomment when ready to verify
 */
// ltl p1 { []<> (floor_request_made[1]==true) } 

/**
 * this property should hold, but does not yet; at any moment during an execution,
 * the opening of the cabin door will happen at some later point.
 *
 * TODO uncomment when ready to verify
 */
// ltl p2 { []<> (cabin_door_is_open==true) } 

//-------------------------------------------------------------------------------------------------
/** type for direction of elevator */
mtype { down, up, none };

/** asynchronous channel to handle passenger requests */
chan request = [NUMBER_OF_FLOORS] of { byte };

/** an array for the status of requests per floor */
bool floor_request_made[NUMBER_OF_FLOORS];

/** status of floor doors of the shaft of the single elevator */
bool floor_door_is_open[NUMBER_OF_FLOORS];

/** wether or not the cabin door is open */
bool cabin_door_is_open;

/** if true the cabin door controler will open the cabin door */
chan update_cabin_door = [0] of { bool };

/** if true the cabin door has been opened */
chan cabin_door_updated = [0] of { bool };

// status and synchronous channels for elevator cabin and engine
byte current_floor = 0;
chan move = [0] of { bool };
chan floor_reached = [0] of { bool };

// synchronous channels for communication between request handler and main control
chan go_to = [0] of { byte };
chan served = [0] of { bool };

//-------------------------------------------------------------------------------------------------
/**
 * cabin door process. Opens the door if update cabin door is true
 * on the channle update_cabin_door.
 */
active proctype cabin_door() {

	do
	:: update_cabin_door?true -> {
            floor_door_is_open[current_floor] = true;
            cabin_door_is_open = true;
            cabin_door_updated!true;
        }
	:: update_cabin_door?false -> {
            cabin_door_is_open = false;
            floor_door_is_open[current_floor] = false; 
            cabin_door_updated!false;
        }
	od;
}

/*
 * process combining the elevator engine and sensors
 */
active proctype elevator_engine() {

	do
	:: move?true -> {
            do
            :: move?false -> break;
            :: floor_reached!true;
            od;
        }
	od;
}

/**
 * DUMMY main control process. Remodel it to control the doors and the engine!
 */ 
active proctype main_control() {

	byte destination; 
	mtype direction;
	do
	:: true -> go_to?destination -> {

            update_cabin_door!false;
            cabin_door_updated?false;

            do // This is the only way of making a sort of function that allows for an early return
            :: true -> {
                    bool DESTINATION_IS_BELOW = (current_floor > destination);
                    bool DESTINATION_IS_ABOVE = (current_floor < destination);
                    if 
                    :: DESTINATION_IS_BELOW -> { 
                            direction = down;
                        }
                    :: DESTINATION_IS_ABOVE -> {
                            direction = up;
                        }
                    :: else -> {
                            break; // early return of the "function"
                        }
                    fi;
                    
                    move!true;

                    do
                    :: current_floor > destination -> {
                            floor_reached?true;
                            current_floor--;
                        }
                    :: current_floor < destination -> {
                            floor_reached?true;
                            current_floor++;
                        } 
                    :: current_floor == destination -> {
                            move!false;
                            direction = none;
                            break;
                        }
                    od;

                    // end of "function" thus we return.
                    break;
                }
            od;

            update_cabin_door!true;
            cabin_door_updated?true;

            // an example assertion.
            assert(0 <= current_floor && current_floor < NUMBER_OF_FLOORS);

            floor_request_made[destination] = false;
            served!true;
        }
	od;
}

/**
 * request handler process. Remodel this process to serve M elevators!
 */
active proctype req_handler() {

	byte destination;
	do
	:: request?destination -> {
            go_to!destination;
            served?true;
        }
	od;
}

/**
 * request button associated to a floor i to request an elevator
 */
active [NUMBER_OF_FLOORS] proctype req_button() {

	do
	:: !floor_request_made[REQUEST_BUTTON_ID] -> {
			atomic {
				//TODO: Ask Rick about arrays
				assert(0 <= REQUEST_BUTTON_ID && REQUEST_BUTTON_ID < NUMBER_OF_FLOORS);
				request!REQUEST_BUTTON_ID;
				floor_request_made[REQUEST_BUTTON_ID] = true;
			}
		}
	od;
}
