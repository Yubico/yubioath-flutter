#!/usr/bin/python

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

import io
import os
import sys
import hmac
import time
import hmac
import base64
import struct
import hashlib
import binascii
import argparse

# Import PBKDF2 function
from pbkdf2 import PBKDF2

# Yubikey NEO managment library
import libykneo

# functions and definitions
import functions

global neo
neo = None
#####################
#Command line input #
#####################
# parser = argparse.ArgumentParser(description='This is a alpha version of the YubiOATH desktop client.\n')
# parser.add_argument('-r','--reader',help='\nSmartCard reader e.g. "Yubikey NEO"', required=False, default="Yubikey NEO")
# parser.add_argument('-c','--command', help='Specify command:\"list_all\" \"calculate\" \"validate\" \"calculate_all\"', required=True)
# parser.add_argument('-n','--account',help='\nCompute code for this specific account', required=False, default=None)
# parser.add_argument('-t','--time',help='\nTime of totp computation', required=False, default=None) 
# parser.add_argument('-p','--password', help='\nPassword to unlock the Yubikey NEO', required=False, default=None)
# args = parser.parse_args()


######################
#commands definition #
######################
commands = {
'list_all': {'cl':0x00,'ins':0xa1,'p1':0x00,'p2':0x00,'data':None},
'calculate': {'cl':0x00,'ins':0xa2,'p1':0x00,'p2':0x01,'data':None},
'validate': {'cl':0x00,'ins':0xa3,'p1':0x00,'p2':0x00,'data':None},
'calculate_all': {'cl':0x00,'ins':0xa4,'p1':0x00,'p2':0x01,'data':None},
'unlock': {'cl':0x00,'ins':0xa3,'p1':0x00,'p2':0x00,'data':None}, 
'delete': {'cl':0x00,'ins':0x02,'p1':0x00,'p2':0x00,'data':None},
'put': {'cl':0x00,'ins':0x01,'p1':0x00,'p2':0x00,'data':None},
'set_code': {'cl':0x00,'ins':0x03,'p1':0x00,'p2':0x00,'data':None},
'unset_code': {'cl':0x00,'ins':0x03,'p1':0x00,'p2':0x00,'data':None}
}



##############################
# connect to the Yubikey NEO #
##############################



def execute_command(command_name, param=None):
		global neo

		####################
		# execute commands #
		####################
		cmd = commands[command_name]
		cred_list = None

		if command_name == 'list_all':
			resp = neo._cmd_ok(cmd['cl'], cmd['ins'], cmd['p1'], cmd['p2'])
			#tag = resp[0]
			#length = resp[1]

		#this calculates all TOTP codes
		elif command_name == 'calculate_all':
			payload = functions.calc_all_payload()
			try:
				resp = neo._cmd_ok(cmd['cl'], cmd['ins'], cmd['p1'], cmd['p2'], payload)
				
			except Exception, e:

				#set the neo to NONE as we need to check for password again
				print e
				neo = None
				return None	

			cred_list = functions.parse_response(resp)


		# this is never used to be implemented
		elif command_name == 'unlock':
			#payload = functions.unlock_applet()
			print "debug123"

		# this command deletes 1 entry from the credential list
		elif command_name == 'delete':
			#prepare payload for the command
			payload = functions.delete_payload(param)
			try:
				resp = neo._cmd_ok(cmd['cl'], cmd['ins'], cmd['p1'], cmd['p2'], payload)
				return True

			except Exception, e:
				#set NEO at None because it may have been unplugged
				neo = None
				print e
				return False

		elif command_name == "put":
			#build the payload for the command
			payload = functions.put_payload(param)
			try:
				resp = neo._cmd_ok(cmd['cl'], cmd['ins'], cmd['p1'], cmd['p2'], payload)
				return True
				
			except Exception, e:
				#set NEO at None because it may have been unplugged
				neo = None
				print e
				return False

		elif command_name == "calculate":
			payload = functions.calculate_payload(param)

			try:
				resp = neo._cmd_ok(cmd['cl'], cmd['ins'], cmd['p1'], cmd['p2'], payload)
				hotp = functions.parse_hotp_response(resp)
				return hotp	
			except Exception, e:
				#neo = None
				print e
				return None

		elif command_name == 'set_code':

			install_id = functions.get_id(neo) #get id
			challenge = '\x1f\x2f\x3f\x4f\x5f\x6f\x7f\x8f'

			#1000 round of pbkdf2
			key = PBKDF2(param, install_id).read(16)
			response = hmac.new(key, challenge, hashlib.sha1).digest()
			#build payload
			payload = functions.set_code_payload(key, response, challenge)

			try: 
				resp = neo._cmd_ok(cmd['cl'], cmd['ins'], cmd['p1'], cmd['p2'], payload)
				return 
				
			except Exception, e:
				print e
				return None

		elif command_name == 'unset_code':

			payload = functions.unset_code_payload()

			try:
				resp = neo._cmd_ok(cmd['cl'], cmd['ins'], cmd['p1'], cmd['p2'], payload)
				return
			except Exception, e:
				print e
				return None


		else:
			print "unknown command"
			sys.exit(1)


		return cred_list	



#
# Check if the NEO is plugged in and if it is protected
#
def check_neo_presence():
	global neo
	#check if NEO is inserted
	if not neo:
		try:
			#use open_key if this gives problems
			neo = libykneo.open_key_multiple_readers(None)
			#return PRESENCE and PROTECTED
			if neo.password_protected:
				#PRESENT AND PROTECTED
				return neo, True
			else:
				#PRESENTE BUT NOT PROTECTED
				return neo, False
		except Exception, e:
			print e
			#The NEO is not plugged in, protected is not checked
			return None, False	
	else:
		if neo.password_protected:
			#PRESENT AND PROTECTED
			return neo, True
		else:
			return neo, False


#
# Unlock the applet with the provided user password
#
def unlock_applet(neo, password):
	
	install_id = functions.get_id(neo) #get id
	challenge = functions.get_challenge(neo) #get challenge

	key = PBKDF2(password, install_id).read(16)
	response = hmac.new(key, challenge, hashlib.sha1).digest()
	cmd = commands['unlock']
	payload = functions.unlock_payload(response)

	try:
		result = neo._cmd_ok(cmd['cl'], cmd['ins'], cmd['p1'], cmd['p2'], payload)
		neo.password_protected = False	
		return True
	except Exception, e:
		#set the NEO to none as we will need to check for password again
		neo = None
		print e
		return False
