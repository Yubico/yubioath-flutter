# Copyright (c) 2013-2014 Yubico AB
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import os
import sys
import time
import struct

from PySide import QtGui



tags = {
'NAME_TAG':0x71,
'NAME_LIST_TAG':0x72,
'KEY_TAG':0x73,
'CHALLENGE_TAG':0x74,
'RESPONSE_TAG':0x75,
'T_RESPONSE_TAG':0x76, #truncated response
'NO_RESPONSE_TAG':0x77, #hotp entry
'PROPERTY_TAG':0x78,
'VERSION_TAG':0x79,
'IMF_TAG':0x7a
}


PUT_INS = 0x01;
DELETE_INS = 0x02;
SET_CODE_INS = 0x03;
RESET_INS = 0x04;

LIST_INS = 0xa1;
CALCULATE_INS = 0xa2;
VALIDATE_INS = 0xa3;
CALCULATE_ALL_INS = 0xa4;
SEND_REMAINING_INS = 0xa5;
	#hmac-sha1 0x01
	#hmac-sha256 0x02
	#totp 0x20
	#hotp 0x10
	#properties 0x01
HMAC_SHA1 = 0x01
TOTP = 0x20
HOTP = 0x10




# A credential is a record with a user account name and a code
class Credential(object):
	#algorithm:
	#totp = 0x20
	#hotp = 0x10
	algorithm = None
	name = ""
	code = 0

	# the class "constructor"  - It's actually an initializer
	def __init__(self, algorithm, name, code):
		self.algorithm = algorithm
		self.name = name
		self.code = code

	def __str__(self):
		return "Name: %s | CODE: %s" % (self.name, self.code)



#ask for the user password and unlock the NEO
def get_user_password(neo):

	password, ok = QtGui.QInputDialog.getText(None, "Password", "Password:", QtGui.QLineEdit.Password)
	if ok:
		return password.encode('utf-8').strip()
	else:
		return None

#get the id and make it look good for pbkdf2
def get_id(neo):
	install_id = ''.join(chr(x) for x in neo.install_id)
	return install_id


#get the challenge and make it look good for pbkdf2	
def get_challenge(neo):
	challenge = ''.join(chr(x) for x in neo.challenge)
	return challenge


#adds a new credential entry in the credential list
def add_entry(algorithm, name, code):
	credential = Credential(algorithm, name, code)
	return credential



#
# compute payload for the calculate_all command and send it to the NEO. 
# basically challenges the NEO with the totp_window
#
def calc_all_payload():
	#compute totp windows
	totp_window = int((time.time() / 30))
	
	#pack it in binary string
	payload_time = struct.pack('>I',totp_window)
	#create padding to 8 bytes
	padding = '\0\0\0\0'
	#calculate the length of the data	
	payload_time_length =  len(padding+payload_time)
	#assamble the payload
	payload = chr(tags['CHALLENGE_TAG']) + chr(payload_time_length) + padding + payload_time

	return payload



#
# format the payload for unlock command
#
def unlock_payload(response):

	# my @apdu = (0x00, 0xa3, 0x00, 0x00, $len, $response_tag, scalar(@resp_p), @resp_p, $challenge_tag, scalar(@$own_chal_p), @$own_chal_p);
	#lenght_all + response_tag + lenght_chall + chall + chall_tag + lengh_own_chall + own_chall
	#test = os.urandom(8)
	#my_challenge = struct.pack('s', test)

	#my challenge should be random 8 bytes
	my_challenge ='\xff\xff\xff\xff\xff\xff\xff\xff'

	payload = chr(tags['RESPONSE_TAG']) + chr(len(response)) + response + chr(tags['CHALLENGE_TAG']) + chr(len(my_challenge)) + my_challenge 


	return payload	


def delete_payload(name):

	payload = chr(tags['NAME_TAG']) + chr(len(name)) + name

	return payload

def put_payload(account):

	#hmac-sha1 0x01
	#hmac-sha256 0x02
	#totp 0x20
	#hotp 0x10
	#properties 0x01

	if account['KEY_TYPE'] == 'time-based':
		key_algorithm = '\x21'
		#hardcoded to 6 not to let the user select 8 by mistake
		digits = 6

	if account['KEY_TYPE'] == 'counter-based':
		key_algorithm = '\x11'
		digits = 6


	#this is optional not used currently
	property_byte = '\0x01'
	#the len+2 is in the protocol documentation
	payload = chr(tags['NAME_TAG']) + chr(len(account['ACCOUNT_NAME'])) + account['ACCOUNT_NAME'] + chr(tags['KEY_TAG']) + chr(len(account['SECRET_KEY'])+2) + key_algorithm + chr(digits) + account['SECRET_KEY']
	#Remaining command parts: + property_byte + IMFTAG +IMF lenght + imf	
	
	# IMF PART NOT IMPLEMENTED YET SET TO DEFAULT
	return payload


#
# creates payload for a setting a new password
#

def set_code_payload(key, response, challenge):
	
	#build payload
	key_algorithm = HMAC_SHA1 | TOTP


	payload = chr(tags['KEY_TAG']) + chr(len(key)+1) + chr(key_algorithm) + key + chr(tags['CHALLENGE_TAG']) + chr(len(challenge)) + challenge + chr(tags['RESPONSE_TAG']) + chr(len(response)) + response

	return payload


def unset_code_payload():

	#set length to zero rest is ignored
	payload = chr(tags['KEY_TAG']) + chr(0)
	return payload


#
# calculate_payload: currnetly is used only to calculate HOTP so be careful!
#
def calculate_payload(hotp_name):

	#compute the payload
	payload = chr(tags['NAME_TAG']) + chr(len(hotp_name)) + hotp_name + chr(tags['CHALLENGE_TAG']) + chr(0)
	
	return payload

#
# parses the response from the HOTP challenge
#
def parse_hotp_response(resp):

	i=0
	if resp[i] is not chr(tags['RESPONSE_TAG']):
		pass
	if resp[i] is not chr(tags['T_RESPONSE_TAG']):
		print "we got a truncated not handled response fix this"
		sys.exit(1)

	i+=1
	hotp_length = ord(resp[i]) - 1 # the -1 is because of the the number od difits following
	i+=1
	digits = ord(resp[i])
	i+=1
	hotp = totp = (struct.unpack(">I", resp[i:i+hotp_length])[0]) % 1000000

	return hotp



#
# parse_response: get the response from challenge all and parses the results
#
def parse_response(resp):


	#list of credentials
	cred_list = []
	
	i=0
	counter = 1
	while i < len(resp):

		#parsing NAME_TAG
		if resp[i] is not chr(tags['NAME_TAG']):
			print "I was expecting NAME_TAG, exiting..."
			sys.exit(1)
		
		#read name length
		i+=1
		name_length = ord(resp[i]) 
		
		#save the name of the entry
		i+=1
		name = resp[i:i+name_length]
		
		#check the tag x076
		i+=name_length

		##########################
		#branch into TOTP or HOTP#
		##########################
		if resp[i] is not chr(tags['T_RESPONSE_TAG']):
			if resp[i] is chr(tags['NO_RESPONSE_TAG']):
				
				
				i+=1
				#get the data length
				data_length = ord(resp[i])
				hotp_length = data_length-1 #hotp length
				
				i+=1
				#read how many digits
				hotp_digits = resp[i]

				#read hotp
				i+=1
				hotp = resp[i:i+hotp_length]
				

				#go on to the next credential
				i+=hotp_length

				if len(str(hotp)) < 6:
					hotp = str(hotp).rjust(6,'0')

				cred_list.append(add_entry('hotp', name, hotp))
				continue
		
		#read data length
		i+=1
		data_length = ord(resp[i])
		totp_length = data_length-1 #this -1 is here because i need to discard 1 byte which indicates otp_digits
		
		#read the number of digits for the totp
		i+=1
		totp_digits = resp[i]
		
		#read the totp
		i+=1
		totp = (struct.unpack(">I", resp[i:i+totp_length])[0]) % 1000000
		

		if len(str(totp)) < 6:
			totp = str(totp).rjust(6,'0')
		i+=totp_length
		
		cred_list.append(add_entry('totp', name, totp))
		
		#loop
	#return
	return cred_list
