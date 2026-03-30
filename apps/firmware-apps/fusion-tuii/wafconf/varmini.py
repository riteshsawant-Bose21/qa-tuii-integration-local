from os import environ


def hasSysroot(conf, platform, target_arch):
    cc = environ.get('CC', 'None')
    if cc.find('--sysroot=') == -1 or cc.find(target_arch) == -1:
        conf.msg('  %s cross checks' % platform, 'Missing sysroot:%s %s' % (target_arch, cc), color='RED')
        return False
    return True


def configure(conf):
    platform = 'varmini'
    arch = 'aarch64'
    if hasSysroot(conf, platform, arch):
        conf.msg('  %s cross checks' % platform, 'OK')
        return

    conf.fatal('Cross-compiler environment is not set up')
