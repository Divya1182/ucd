/*
 This class will have definition for all properties from config server.
 Scope Name: Pharmacy Benefits Builder
 */

package com.esrx.services.pbb.utils;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class PBBConfigServerParams {
    @Value("${app.name}")  public String appName;

    @Value("${app.version}")  public String appVersion;

    @Value("${app.environment}")  public String environment;

    @Value("${app.status}") public String status;

//    @Value("${api.esrx.base.url}") public String baseUrl;
//
//    @Value("${com.esrx.elevate.services.uri}") public String elevateUri;

//    @Value("${idp.location}") public String idpLocation; // this will be used to read idp location when we start implementing okta
    // for postgres DB
    @Value("${spring.postgres.datasource.jdbc-url}") public String pgURL;

    @Value("${spring.postgres.datasource.sslrootcert}") public String sslRootCert;

    @Value("${spring.postgres.datasource.sslpassword}")  public String sslPwd;

    @Value("${spring.postgres.datasource.sslcert}") public String sslCert;

    @Value("${spring.postgres.datasource.sslkey}") public String sslKey;

    @Value("${spring.postgres.datasource.sslmode}") public String sslMode;

    @Value("${spring.postgres.datasource.ssltrue}") public String sslTrue;

    @Value("${spring.postgres.datasource.sslcompression}") public String sslCompression;

    @Value("${benefitsetuptype.query}") public String benefitTypeQuery;

}
