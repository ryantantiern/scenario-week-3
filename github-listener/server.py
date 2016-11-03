#!/usr/bin/env python
# Github listener server for integration with Github webhooks.
# Executes deployment script when event is dispatched from Github.
from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
import json
import time
import subprocess
import hmac, hashlib

# Config
PORT_NUMBER = 8080
SECRET = "strange1"
DEPLOYMENT_SCRIPT_LOCATION = "~/strange-references/deploy.sh"

class requestHandler(BaseHTTPRequestHandler):
    
    # Silence log messages
    def log_message(self, format, *args):
        return

    # Handler for GET requests
    def do_GET(self):
        log('GET received.')
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        # Send the html message
        self.wfile.write("WHY ARE YOU HERE?")
        
    # Handler for POST requests
    def do_POST(self):
        log("Incoming message...")
        githubSignature = self.headers.getheader("X-Hub-Signature")
        githubEvent = self.headers.getheader("X-GitHub-Event")
        
        # For debug:
        log("Github event received: %s." % githubEvent)
        log("Github signature: %s." % githubSignature)
        
        content = self.rfile.read(int(self.headers.getheader('Content-Length')))
        # For debug:
        #print content
        
        hexdigest = hmac.new(SECRET, msg=content, digestmod=hashlib.sha1).hexdigest()
        log("Computed signature: %s." % hexdigest)
        
        # Authenticate the message
        if githubSignature == "sha1=" + hexdigest:
            log("Authentication success.")
            
            if githubEvent == "push":
                parsed_json = json.loads(content)
                log("Repository %s was updated by %s." % (parsed_json["repository"]["name"], parsed_json["pusher"]["name"]))
                
                returnvalue = -1
                
                # Execute deployment script
                try:
                    returnvalue = subprocess.call([DEPLOYMENT_SCRIPT_LOCATION])
                except:
                    log("WARNING: Deployment script could not be found or failed to run.")
                
                if returnvalue == 0:
                    log("SUCCESS: Deployment script started.")
                else:
                    log("FAILED: Deployment failed.")
            
        else:
            log("Incorrect signature - disregarding message.")
        
        log("-----")
        
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        return
    
def log(message):
    print "[%s] %s" % (time.ctime(), message)
        
try:
    server = HTTPServer(('', PORT_NUMBER), requestHandler)
    log("Started Github listening server on port %s." % PORT_NUMBER)
    
    server.serve_forever()
    
except KeyboardInterrupt:
    log("Shutting down server.")
    server.socket.close()