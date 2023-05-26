#!/bin/bash

PSQL="psql -X --username=postgres --dbname=salon_db --tuples-only -c"

SERVICE_LIST=$($PSQL "SELECT * FROM services")

SHOW_SERVICE_LIST() {
	if [[ $1 ]]
	then
		echo $1
	fi

	echo -e "\nPick one of the above services: "
	echo "$SERVICE_LIST" | while read SERVICE_ID BAR NAME
	do 
		echo "$SERVICE_ID) $NAME"
	done

	READ_SERVICE
}

READ_SERVICE() {
	read SERVICE_ID_SELECTED
	if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
	then
		SHOW_SERVICE_LIST "Please enter a valid service ID"
	else
		# get service_id from service_id_selected
		SERVICE_ID_FOUND=$($PSQL "SELECT service_id FROM services WHERE service_id=$SERVICE_ID_SELECTED")
		# if not found
		if [[ -z $SERVICE_ID_FOUND ]]
		then
			SHOW_SERVICE_LIST "Please enter a valid service ID"
		else
			echo -e "\nEnter service time: "
			read SERVICE_TIME
			# get phone number from customer_phone
			echo -e "\nEnter your phone number: "
			read CUSTOMER_PHONE
			
			if [[ ! -z $CUSTOMER_PHONE ]]
			then
				CUSTOMER_PHONE_FOUND=$($PSQL "SELECT phone FROM customers WHERE phone='$CUSTOMER_PHONE'")
				# if not found
				if [[ -z $CUSTOMER_PHONE_FOUND ]]
				then
					echo -e "\nEnter your name: "
					read CUSTOMER_NAME

					# insert customer_name and customer_phone into customers table
					INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME','$CUSTOMER_PHONE')")
					
					if [[ $INSERT_CUSTOMER_RESULT = 'INSERT 0 1' ]]
					then
						echo "Inserted a customer: $CUSTOMER_NAME"
						CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
						INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")

						if [[ $INSERT_APPOINTMENT_RESULT = 'INSERT 0 1' ]]
						then
							SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")
							echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
						fi
					fi
				else
					# get customer name from their phone (unique)
					# insert into appointments table
					CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
					INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")

					if [[ $INSERT_APPOINTMENT_RESULT = 'INSERT 0 1' ]]
					then
						SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")
						echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
					fi
				fi
			fi
			
		fi
	fi
	
}


SHOW_SERVICE_LIST