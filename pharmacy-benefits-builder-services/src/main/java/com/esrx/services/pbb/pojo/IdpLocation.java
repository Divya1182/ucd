/**
 * Pojo to define all attributes required for Idp information along with environment.
 * @author P57026
 */

package com.esrx.services.pbb.pojo;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import lombok.Data;

@Data
@JsonSerialize(include=JsonSerialize.Inclusion.NON_NULL)
public class IdpLocation {
    private String statusCode;
    private String idpLocation; // this variable will be used when implementing okta for idp location.

}
