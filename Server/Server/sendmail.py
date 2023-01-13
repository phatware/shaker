import smtplib
from pin import pin_gen

from string import Template

from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

class sendMail:

    def __init__(self, email_from, login_passwd, host, port):
        self.email_from = email_from
        self.host = host
        self.port = port

        # set up the SMTP server
        self.mail = smtplib.SMTP(host=self.host, port=self.port)
        self.mail.ehlo()
        self.mail.starttls()
        self.mail.login(email_from, login_passwd)

    def __del__(self):
        # Terminate the SMTP session and close the connection
        self.mail.quit()

    def read_template(self, filename):
        """
        Returns a Template object comprising the contents of the
        file specified by filename.
        """

        with open(filename, 'r') as template_file:
            template_file_content = template_file.read()
        return Template(template_file_content)

    def send(self, email_to, name, payload, subject = 'Activate account', template = 'activate_account'):

        filename = template + '.txt'
        message_template = self.read_template(filename)

        msg = MIMEMultipart()       # create a message

        # add in the actual person name to the message template
        message = message_template.substitute(NAME=name, PAYLOAD=payload)
        # Prints out the message body for our sake
        print(message)

        # setup the parameters of the message
        msg['From'] = self.email_from
        msg['To'] = email_to
        msg['Subject'] = subject
        # msg.preamble = subject

        # add in the message body
        msg.attach(MIMEText(message, 'plain'))

        # send the message via the server set up earlier.
        self.mail.sendmail(self.email_from, email_to, msg.as_string())
        del msg


if __name__ == '__main__':
    pin  = pin_gen(6)
    sm = sendMail("shaker@phatware.com", "longlongpassword123!", "mail.phatware.com", 587)
    sm.send('stanmiasnikov@gmail.com', 'Stan', pin, 'Activate Device', template = 'activate_device')
    del sm
