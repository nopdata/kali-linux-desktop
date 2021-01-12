from flask import (Flask,
                   request,
                   abort,
                   )
import os


# Flask app
app = Flask(__name__,
            static_folder='static', static_url_path='',
            instance_relative_config=True)
CONFIG = os.environ.get('CONFIG') or 'config.Development'
app.config.from_object('config.Default')
app.config.from_object(CONFIG)

# logging
import logging
from log.config import LoggingConfiguration
LoggingConfiguration.set(
    logging.DEBUG if os.getenv('DEBUG') else logging.INFO,
    'lightop.log', name='Web')


import json
from functools import wraps
import subprocess
import time


def exception_to_json(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        try:
            result = func(*args, **kwargs)
            return result
        except (BadRequest,
                KeyError,
                ValueError,
                ) as e:
            result = {'error': {'code': 400,
                                'message': str(e)}}
        except PermissionDenied as e:
            result = {'error': {'code': 403,
                                'message': ', '.join(e.args)}}
        except (NotImplementedError, RuntimeError, AttributeError) as e:
            result = {'error': {'code': 500,
                                'message': ', '.join(e.args)}}
        return json.dumps(result)
    return wrapper


class PermissionDenied(Exception):
    pass


class BadRequest(Exception):
    pass


HTML_INDEX = '''<html><head>
    <script type="text/javascript">
        var w = window,
        d = document,
        e = d.documentElement,
        g = d.getElementsByTagName('body')[0],
        x = w.innerWidth || e.clientWidth || g.clientWidth,
        y = w.innerHeight|| e.clientHeight|| g.clientHeight;
        window.location.href = "redirect.html?width=" + x + "&height=" + (parseInt(y));
    </script>
    <title>Page Redirection</title>
</head><body></body></html>'''


HTML_REDIRECT = '''<html><head>
    <script type="text/javascript">
        var port = window.location.port;
        if (!port)
            port = window.location.protocol[4] == 's' ? 443 : 80;
        window.location.href = "vnc.html?autoconnect=1&autoscale=0&quality=3";
    </script>
    <title>Page Redirection</title>
</head><body></body></html>'''


@app.route('/')
def index():
    return HTML_INDEX


@app.route('/redirect.html')
def redirectme():
    
    env = {'width': 1024, 'height': 768}
    if 'width' in request.args:
        env['width'] = request.args['width']
    if 'height' in request.args:
        env['height'] = request.args['height']

    # sed
    subprocess.check_call(r"sed -i 's#^command=/usr/bin/Xvfb.*$#command=/usr/bin/Xvfb :1 -screen 0 {width}x{height}x16#' /etc/supervisor/conf.d/supervisord.conf".format(**env), shell=True)
    # supervisorctrl reload
    subprocess.check_call(r"supervisorctl reload", shell=True)

    # check all running
    for i in range(3):
        output = subprocess.check_output(r"supervisorctl status | grep RUNNING | wc -l", shell=True)
        if output.decode("utf-8").strip() == "6":
            return HTML_REDIRECT
        else:
            # supervisorctrl reload
            subprocess.check_call(r"supervisorctl reload", shell=True)
        time.sleep(3)

    abort(500, 'service is not ready, please restart container')


if __name__ == '__main__':
    app.run(host=app.config['ADDRESS'], port=app.config['PORT'])
