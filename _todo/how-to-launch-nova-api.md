1. how to launch nova-api

    /usr/bin/nova-api --config-file=/etc/nova/nova.conf

    /etc/nova/api-paste.ini

    [composite:osapi_compute]
    use = call:nova.api.openstack.urlmap:urlmap_factory
    /: oscomputeversions
    /v1.1: openstack_compute_api_v2
    /v2: openstack_compute_api_v2


2. what is in /usr/bin/nova-api

    if __name__ == '__main__':
        flags.parse_args(sys.argv)
        logging.setup("nova")
        utils.monkey_patch()
        launcher = service.ProcessLauncher()
        for api in ['osapi_compute']:
            server = service.WSGIService(api)
            launcher.launch_server(server, workers=server.workers or 1)
        launcher.wait()

3. wsgi service

    /nova/service.py
    class WSGIService(object):
        """Provides ability to launch API from a 'paste' configuration."""

        def __init__(self, name, loader=None):
            """Initialize, but do not start the WSGI server.

            :param name: The name of the WSGI server given to the loader.
            :param loader: Loads the WSGI application using the given name.
            :returns: None

            """
            self.name = name
            self.manager = self._get_manager()
            self.loader = loader or wsgi.Loader()
            self.app = self.loader.load_app(name)
            self.host = getattr(FLAGS, '%s_listen' % name, "0.0.0.0")
            self.port = getattr(FLAGS, '%s_listen_port' % name, 0)
            self.workers = getattr(FLAGS, '%s_workers' % name, None)
            self.server = wsgi.Server(name,
                                      self.app,
                                      host=self.host,
                                      port=self.port)
            # Pull back actual port used
            self.port = self.server.port

    /nova/wsgi.py
    class Loader(object):
        """Used to load WSGI applications from paste configurations."""

        def __init__(self, config_path=None):
            """Initialize the loader, and attempt to find the config.

            :param config_path: Full or relative path to the paste config.
            :returns: None

            """
            config_path = config_path or FLAGS.api_paste_config
            if os.path.exists(config_path):
                self.config_path = config_path
            else:
                self.config_path = FLAGS.find_file(config_path)
            if not self.config_path:
                raise exception.ConfigNotFound(path=config_path)

        def load_app(self, name):
            """Return the paste URLMap wrapped WSGI application.

            :param name: Name of the application to load.
            :returns: Paste URLMap object wrapping the requested application.
            :raises: `nova.exception.PasteAppNotFound`

            """
            try:
                LOG.debug(_("Loading app %(name)s from %(path)s") %
                          {'name': name, 'path': self.config_path})
                return deploy.loadapp("config:%s" % self.config_path, name=name)
            except LookupError as err:
                LOG.error(err)
                raise exception.PasteAppNotFound(name=name, path=self.config_path)

4. paste.deploy.loadapp

    /paste/deplpy/loadwsgi.py
    def loadapp(uri, name=None, **kw):
        //uri = config:/etc/nova/api-paste.ini
        //name = osapi_compute
        return loadobj(APP, uri, name=name, **kw)

    class _ObjectType(object):

        name = None
        egg_protocols = None
        config_prefixes = None

        def __init__(self):
            # Normalize these variables:
            self.egg_protocols = [_aslist(p) for p in _aslist(self.egg_protocols)]
            self.config_prefixes = [_aslist(p) for p in _aslist(self.config_prefixes)]

        def __repr__(self):
            return '<%s protocols=%r prefixes=%r>' % (
                self.name, self.egg_protocols, self.config_prefixes)

        def invoke(self, context):
            assert context.protocol in _flatten(self.egg_protocols)
            return fix_call(context.object,
                            context.global_conf, **context.local_conf)

    class _App(_ObjectType):

        name = 'application'
        egg_protocols = ['paste.app_factory', 'paste.composite_factory',
                         'paste.composit_factory']
        config_prefixes = [['app', 'application'], ['composite', 'composit'],
                           'pipeline', 'filter-app']

        def invoke(self, context):
            if context.protocol in ('paste.composit_factory',
                                    'paste.composite_factory'):
                return fix_call(context.object,
                                context.loader, context.global_conf,
                                **context.local_conf)
            elif context.protocol == 'paste.app_factory':
                return fix_call(context.object, context.global_conf,
                                    **context.local_conf)
            else:
                assert 0, "Protocol %r unknown" % context.protocol

    APP = _App()

    def loadobj(object_type, uri, name=None, relative_to=None,
                global_conf=None):
        context = loadcontext(
            object_type, uri, name=name, relative_to=relative_to,
            global_conf=global_conf)
        return context.create()

    def loadcontext(object_type, uri, name=None, relative_to=None,
                    global_conf=None):
        if '#' in uri:
            if name is None:
                uri, name = uri.split('#', 1)
            else:
                # @@: Ignore fragment or error?
                uri = uri.split('#', 1)[0]
        if name is None:
            name = 'main'
        if ':' not in uri:
            raise LookupError("URI has no scheme: %r" % uri)
        scheme, path = uri.split(':', 1)
        scheme = scheme.lower()
        if scheme not in _loaders:
            raise LookupError(
                "URI scheme not known: %r (from %s)"
                % (scheme, ', '.join(_loaders.keys())))
        return _loaders[scheme](
            object_type,
            uri, path, name=name, relative_to=relative_to,
            global_conf=global_conf)

    def _loadconfig(object_type, uri, path, name, relative_to,
                    global_conf):
        isabs = os.path.isabs(path)
        # De-Windowsify the paths:
        path = path.replace('\\', '/')
        if not isabs:
            if not relative_to:
                raise ValueError(
                    "Cannot resolve relative uri %r; no relative_to keyword "
                    "argument given" % uri)
            relative_to = relative_to.replace('\\', '/')
            if relative_to.endswith('/'):
                path = relative_to + path
            else:
                path = relative_to + '/' + path
        if path.startswith('///'):
            path = path[2:]
        path = unquote(path)
        loader = ConfigLoader(path)
        if global_conf:
            loader.update_defaults(global_conf, overwrite=False)
        return loader.get_context(object_type, name, global_conf)

    _loaders['config'] = _loadconfig

