/**
 * Pojo to define all attributes required to map in user info service.
 * @author P57026
 */
package com.esrx.services.pbb.pojo;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;


@Data
@Slf4j
@JsonIgnoreProperties(ignoreUnknown = true)
public class UserInfo {
	private String userId;
	private String firstName;
	private String lastName;
	private String emailId;
	private String groupNames;
	private String x_jwt_assertion;
	private String appCookiesDomain;
	private String environment;
	private String pgmIds;
}
