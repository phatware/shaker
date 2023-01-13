import json
import base64
from urllib.parse import quote
from api_setup import _config
from sendmail import sendMail
from database import Database

def sendActivationMail(db, user_id, email_to, pin):
    user = db.findUser(user_id)
    sm = sendMail(_config['email_from'], _config['email_pass'], _config['email_host'], _config['email_port'])
    sm.send(email_to, user[1], pin, subject = 'Activate Account', template = 'activate_device')

def sendInvitationEmail(from_name, from_email, to_email, to_name=''):
    url = _config['download_url']
    subject = from_name + ' wants to send you a file'
    # initialize email sender
    if from_email == "":
        from_email = _config['email_from']
    sm = sendMail(from_email, _config['email_pass'], _config['email_host'], _config['email_port'])
    sm.send(to_email, to_name, url, subject = subject, template = 'invite')

def sendGenericEmail(email_to, name, payload, subject = 'Activate account', template = 'activate_account'):
    sm = sendMail(_config['email_from'], _config['email_pass'], _config['email_host'], _config['email_port'])
    sm.send(email_to, name, payload, subject = subject, template = template)
