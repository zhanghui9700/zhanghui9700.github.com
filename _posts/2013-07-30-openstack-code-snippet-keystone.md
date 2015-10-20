---
layout: post
title: openstack code snippets keystone
category: openstack
tags: [linux, openstack, python]
---


<a href="#user_passwd">[1]Check User Password</a>
</br>

---

<a id="user_passwd"></a>
####Check User Password####

{% highlight python %}
import passlib.hash

CONF.crypt_strength = 4000

def trunc_password(password):
    """Truncate passwords to the MAX_PASSWORD_LENGTH."""
    if len(password) > MAX_PASSWORD_LENGTH:
        return password[:MAX_PASSWORD_LENGTH]
    else:
        return password


def hash_password(password):
    """Hash a password. Hard."""
    password_utf8 = password.encode('utf-8')
    if passlib.hash.sha512_crypt.identify(password_utf8):
        return password_utf8
    h = passlib.hash.sha512_crypt.encrypt(password_utf8,
                                          rounds=CONF.crypt_strength)
    return h


def check_password(password, hashed):
    """Check that a plaintext password matches hashed.

    hashpw returns the salt value concatenated with the actual hash value.
    It extracts the actual salt if this value is then passed as the salt.

    """
    if password is None:
        return False
    password_utf8 = password.encode('utf-8')
    return passlib.hash.sha512_crypt.verify(password_utf8, hashed)
{% endhighlight %}

---


<a id="looping_call"></a>
####Looping Call####

{% highlight python%}

{% endhighlight%}
