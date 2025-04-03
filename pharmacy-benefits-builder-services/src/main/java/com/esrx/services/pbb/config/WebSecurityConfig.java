package com.esrx.services.pbb.config;

import com.esrx.inf.spring.boot.autoconfigure.security.HttpSecurityConfigurer;
import com.esrx.inf.spring.boot.autoconfigure.security.HttpServiceSecurityAutoConfiguration;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.stereotype.Component;


/**
 * Created by p57026.
 */
@Component
@Slf4j
public class WebSecurityConfig {

    private WebSecurityConfig() {}

    @Profile("local")
    @EnableWebSecurity
    public static class LocalSecurityConfig extends HttpServiceSecurityAutoConfiguration {
        @Override
        public void configure(HttpSecurity httpSecurity) throws Exception {
            log.info("Inside LocalSecurityConfig.configure");
            httpSecurity.authorizeRequests().antMatchers("/**").permitAll();
            super.configure(httpSecurity);
        }
    }

    @EnableWebSecurity
    public static class ActiveSecurityConfig implements HttpSecurityConfigurer {
        @Override
        public void configure(HttpSecurity httpSecurity) throws Exception {
            log.info("Inside ActiveSecurityConfig.configure");
            httpSecurity.authorizeRequests()
                    .antMatchers("/management/**").permitAll()
                    .antMatchers("/").permitAll()
                    .antMatchers("/pbb/v*/benefits/**").permitAll();

        }
    }
}