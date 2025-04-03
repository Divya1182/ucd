/**
 * Main class to initiate Pharmacy Benefits Build Service Component.
 * @author P57026
 *
 */
package com.esrx.services.pbb;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.security.servlet.SecurityAutoConfiguration;
import org.springframework.context.annotation.ComponentScan;

import java.util.Arrays;

@SpringBootApplication(exclude = { SecurityAutoConfiguration.class})
@Slf4j
public class PharmacyBenefitsBuildServiceMain {
	public static void main(String[] args) {
		SpringApplication.run(PharmacyBenefitsBuildServiceMain.class, args);
		log.info("PharmacyBenefitsBuildServiceMain.main=>Hello & Welcome to PBB Service.");
	}
}