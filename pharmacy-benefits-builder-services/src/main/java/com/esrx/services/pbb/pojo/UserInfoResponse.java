/**
 * this class will be used for user information response.
 *
 * @author P57026
 */

package com.esrx.services.pbb.pojo;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;

@Data
@Slf4j
@JsonIgnoreProperties(ignoreUnknown = true)
public class UserInfoResponse {

	private String statusCode;
	private String statusMessage;
	private UserInfo userInfo;
}
	
