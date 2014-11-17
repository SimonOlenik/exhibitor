package com.netflix.exhibitor.application;

import com.google.common.io.Closeables;
import com.netflix.exhibitor.standalone.ExhibitorCreator;
import com.netflix.exhibitor.standalone.ExhibitorCreatorExit;
import com.netflix.exhibitor.standalone.SecurityArguments;
import org.apache.commons.daemon.Daemon;
import org.apache.commons.daemon.DaemonContext;
import org.apache.commons.daemon.DaemonInitException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.Closeable;

public class DaemonMain implements Daemon {

    private final static Logger log = LoggerFactory.getLogger(DaemonMain.class);
    private ExhibitorCreator creator;
    private ExhibitorMain exhibitorMain;

    @Override
    public void init(DaemonContext daemonContext) throws DaemonInitException, Exception {
        log.debug("daemon init() began");
        String[] args = daemonContext.getArguments();
        try {
            creator = new ExhibitorCreator(args);
        } catch (ExhibitorCreatorExit exit) {
            if ( exit.getError() != null) {
                System.err.println(exit.getError());
            }
            exit.getCli().printHelp();
            return;
        }
        log.debug("daemon init() finished");
    }

    @Override
    public void start() throws Exception {
        log.debug("daemon start() began");
        SecurityArguments securityArguments = new SecurityArguments(
                creator.getSecurityFile(),
                creator.getRealmSpec(),
                creator.getRemoteAuthSpec());
        exhibitorMain = new ExhibitorMain (
                        creator.getBackupProvider(),
                        creator.getConfigProvider(),
                        creator.getBuilder(),
                        creator.getHttpPort(),
                        creator.getSecurityHandler(),
                        securityArguments
                );

        ExhibitorMain.setShutdown(exhibitorMain);

        exhibitorMain.start();
        try {
            exhibitorMain.join();
        } finally {
            exhibitorMain.close();

            for (Closeable closeable : creator.getCloseables()) {
                closeable.close();
                Closeables.closeQuietly(closeable);
            }
        }

        log.debug("daemon start() finished");
    }

    @Override
    public void stop() throws Exception {
        log.debug("daemon stop() began");
        exhibitorMain.close();
        for (Closeable closeable : creator.getCloseables()) {
            Closeables.closeQuietly(closeable);
        }
        log.debug("daemon stop() finished");
    }

    @Override
    public void destroy() {
        log.debug("daemon destroy() began");
        log.debug("daemon destroy() finished");
    }
}
