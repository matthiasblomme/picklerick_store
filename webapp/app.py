from glob import glob
from flask import Flask, jsonify, render_template, request, send_from_directory, redirect
from confluent_kafka import Producer, Consumer, KafkaError, KafkaException
from bson import json_util
import json,datetime,uuid

app = Flask(__name__)
KafkaKey=''
UserID=''
StoreID=''
VisitID=''
Cart=[]
Total=0

@app.route('/')
def index():
    return render_template('index.html')   

@app.route("/static/<path:path>")
def static_dir(path):
    return send_from_directory("static", path)

def error_cb(err):
    """ The error callback is used for generic client errors. These
        errors are generally to be considered informational as the client will
        automatically try to recover from all errors, and no extra action
        is typically required by the application.
        For this example however, we terminate the application if the client
        is unable to connect to any broker (_ALL_BROKERS_DOWN) and on
        authentication errors (_AUTHENTICATION). """

    print("Client error: {}".format(err))
    if err.code() == KafkaError._ALL_BROKERS_DOWN or \
       err.code() == KafkaError._AUTHENTICATION:
        # Any exception raised from this callback will be re-raised from the
        # triggering flush() or poll() call.
        raise KafkaException(err)
       
p = Producer({
'bootstrap.servers': 'pkc-lzvrd.us-west4.gcp.confluent.cloud:9092',
'security.protocol': 'SASL_SSL',
'sasl.mechanism': 'PLAIN',
'sasl.username': 'W43E4KMZ3O4CG6OZ',
'sasl.password': 'PGlv2Ne5ta5RAYn0yPofoQoQRpOcMrqrEK0KGS1n3XG/b/lia5dTycKvBDMvPEjo',
'error_cb': error_cb,
})
c = Consumer({
'bootstrap.servers': 'pkc-lzvrd.us-west4.gcp.confluent.cloud:9092',
'security.protocol': 'SASL_SSL',
'sasl.mechanism': 'PLAIN',
'sasl.username': 'W43E4KMZ3O4CG6OZ',
'sasl.password': 'PGlv2Ne5ta5RAYn0yPofoQoQRpOcMrqrEK0KGS1n3XG/b/lia5dTycKvBDMvPEjo',
'group.id': "foo",
'error_cb': error_cb,
})
@app.route("/scanFunction/<string:decodedText>", methods=['POST'])
def scanFunction(decodedText):
    print('scanFunction')
    today = datetime.datetime.now()
    date_time = today.strftime("%m/%d/%Y/ %H:%M:%S")
    print(date_time)
    scannedCode=json.loads(decodedText)
    print(scannedCode)
    data = { 
        'customerId': UserID,
        'itemId' : scannedCode,
        'scanTimestamp': date_time,
        'visitId' : VisitID,
        'storeId' : StoreID
    }  
    p.produce('item_scans', key=KafkaKey, value=json.dumps(data, default=json_util.default).encode('utf-8'))
    p.poll(1)
    p.flush(10) 
    return "Nothing"
    
    
running = True
@app.route('/cartFunction')
def consume_loop():
    global Cart
    Cart=[]
    Retrycount=0 
    NotFoundcount=0
    msg_found = False
    print('cartFunction')
    try:
        print("try")
        c.subscribe(topics=['st_scan_item_details'])
        print("subscribed")
        msg_count = 0
        while running:
            print("in loop")
            msg = c.poll(timeout=1.0)
            if msg is None:
                if msg_found:
                    print("no messages")
                    Retrycount +=1
                    if Retrycount == 2:
                        break
                else:
                    NotFoundcount += 1
                    if NotFoundcount == 5:
                        break
                    continue
            if msg.error():
                if msg.error().code() == KafkaError._PARTITION_EOF:
                    # End of partition event
                    print('%% %s [%d] reached end at offset %d\n' %(msg.topic(), msg.partition(), msg.offset()))
                elif msg.error():
                    raise KafkaException(msg.error())
            else:
                msg_process(msg)
                msg_found = True
                Retrycount = 0
                msg_count += 1
                if msg_count % 10 == 0:
                    c.commit(asynchronous=False)
    finally:
        # Close down consumer to commit final offsets.
        print("closing consumer")
        #c.close()
        calculateTotal()
        return render_template('cart.html', Cart=Cart, Total=Total)
        
        
def shutdown():
    running = False    

def msg_process(msg):
    print("in msg_process")
    print(f"key: {msg.key().decode('utf-8')}, value: {msg.value().decode('utf-8')}") 
    Cart.append(json.loads(msg.value().decode('utf-8')))
    

def calculateTotal():
    global Total
    Total=0
    for x in Cart:
        Total += x["IT_UNITPRICE"]

@app.route('/buyFunction')
def buyFunction():
    print('buyFunction')
    global KafkaKey
    global UserID
    global StoreID
    global VisitID
    today = datetime.datetime.now()
    date_time = today.strftime("%m/%d/%Y/ %H:%M:%S")
    data = {
        'customerId': UserID,
        'visitId' : VisitID,
        'storeId' : StoreID,
        'buyingTimestamp': date_time
    }
    print()
    p.produce('purchases', key=KafkaKey, value=json.dumps(data, default=json_util.default).encode('utf-8'))
    p.poll(1)
    p.flush(10)
    KafkaKey=''
    UserID=''
    StoreID=''
    VisitID=''
    return "Nothing"

@app.route('/trackFunction',methods=['POST'])
def trackFunction():
    print('trackFunction')
    print(request.form['location'])
    today = datetime.datetime.now()
    date_time = today.strftime("%m/%d/%Y/ %H:%M:%S")
    data = {
        'customerId': UserID,
        'visitId' : VisitID,
        'storeId' : StoreID,
        'locationId' : request.form['location'],
        'trackingTimestamp': date_time
    }
    p.produce('customer_tracking', key=KafkaKey, value=json.dumps(data, default=json_util.default).encode('utf-8'))
    p.poll(1)
    p.flush(10)
    return "Nothing"

@app.route('/',methods=['POST'])
def login():
    print('loginFunction')
    if request.method == 'POST':
        global KafkaKey
        global UserID
        global StoreID
        global VisitID
        UserID = request.form['UserID']
        StoreID = request.form['StoreID']
        KafkaKey = UserID
        VisitID=str(uuid.uuid4())
        return render_template('store.html')
    
@app.route('/scanPage')
def scanPage():
    return render_template('scan.html')

@app.route('/storePage')
def storePage():
    return render_template('store.html')

if __name__ == '__main__':
   app.run(host='0.0.0.0',ssl_context='adhoc')