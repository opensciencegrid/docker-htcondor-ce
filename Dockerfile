FROM opensciencegrid/software-base:fresh
LABEL maintainer "OSG Software <help@opensciencegrid.org>"

RUN groupadd -g 64 -r condor
RUN useradd -r -g condor -d /var/lib/condor -s /sbin/nologin \
    -u 64 -c "Owner of HTCondor Daemons" condor

# FIXME: get the latest osg-configure so that fetch-crl errors don't prevent CE configuration:
# https://opensciencegrid.atlassian.net/browse/SOFTWARE-4364
RUN yum install -y --enablerepo=osg-testing \
                   --enablerepo=osg-upcoming-testing \
                   osg-ce-condor \
                   certbot && \
    yum update -y --enablerepo=osg-development osg-configure && \
    yum clean all && \
    rm -rf /var/cache/yum/

COPY 20-htcondor-ce-setup.sh /etc/osg/image-config.d/

COPY 99-container.conf /usr/share/condor-ce/config.d/

# TODO: Drop this after implementing non-root Gratia probes
# https://opensciencegrid.atlassian.net/browse/SOFTWARE-3975
RUN chmod 1777 /var/lib/gratia/tmp
RUN touch /var/lock/subsys/gratia-probes-cron

# do the bad thing of overwriting the existing cron job for fetch-crl
ADD fetch-crl /etc/cron.d/fetch-crl
RUN chmod 644 /etc/cron.d/fetch-crl

# Include script to drain the CE and upload accounting data to prepare for container teardown
COPY drain-ce.sh /usr/local/bin/

# Manage HTCondor-CE with supervisor
COPY 10-htcondor-ce.conf /etc/supervisord.d/

ENTRYPOINT ["/usr/local/sbin/supervisord_startup.sh"]
