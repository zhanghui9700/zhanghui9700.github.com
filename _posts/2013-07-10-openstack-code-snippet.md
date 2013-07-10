---
layout: post
title: openstack code snippets
category: openstack
tags: [linux, openstack, python]
---

{% include JB/setup %}

<a href="#get_my_ip">[1]Get My Host IP</a>
</br>
<a href="#looping_call">[2]Looping Call</a>
</br>

---

<a id="get_my_ip"></a>
####Get My Host IP####

{% highlight python %}
def _get_my_ip():
"""
Returns the actual ip of the local machine.

This code figures out what source address would be used if some traffic
were to be sent out to some well known address on the Internet. In this
case, a Google DNS server is used, but the specific address does not
matter much.  No traffic is actually sent.
"""
try:
    csock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    csock.connect(('8.8.8.8', 80))
    (addr, port) = csock.getsockname()
    csock.close()
    return addr
except socket.error:
    return "127.0.0.1"
{% endhighlight %}

---


<a id="looping_call"></a>
####Looping Call####

{% highlight python%}
from eventlet import event
from eventlet import greenthread

class LoopingCallDone(Exception):
    """Exception to break out and stop a LoopingCall.

    The poll-function passed to LoopingCall can raise this exception to
    break out of the loop normally. This is somewhat analogous to
    StopIteration.

    An optional return-value can be included as the argument to the exception;
    this return-value will be returned by LoopingCall.wait()

    """

    def __init__(self, retvalue=True):
        """:param retvalue: Value that LoopingCall.wait() should return."""
        self.retvalue = retvalue

class LoopingCall(object):
    def __init__(self, f=None, *args, **kw):
        self.args = args
        self.kw = kw
        self.f = f
        self._running = False

    def start(self, interval, initial_delay=None):
        self._running = True
        done = event.Event()

        def _inner():
            if initial_delay:
                greenthread.sleep(initial_delay)

            try:
                while self._running:
                    self.f(*self.args, **self.kw)
                    if not self._running:
                        break
                    greenthread.sleep(interval)
            except LoopingCallDone, e:
                self.stop()
                done.send(e.retvalue)
            except Exception:
                LOG.exception(_('in looping call'))
                done.send_exception(*sys.exc_info())
                return
            else:
                done.send(True)

        self.done = done

        greenthread.spawn(_inner)
        return self.done

    def stop(self):
        self._running = False

    def wait(self):
        return self.done.wait()


Demo(how to use):
# Waiting for completion of live_migration.
timer = utils.LoopingCall(f=None)

def wait_for_live_migration():
    """waiting for live migration completion"""
    try:
        self.get_info(instance_ref)['state']
    except exception.NotFound:
        timer.stop()
        post_method(ctxt, instance_ref, dest, block_migration)

timer.f = wait_for_live_migration
timer.start(interval=0.5).wait()

{% endhighlight%}
