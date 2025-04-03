/**
 * service class where all the logics are written for different api
 *
 * @author P57026
 */
package com.esrx.services.pbb.service;

import com.esrx.services.pbb.domain.BenefitSetUp;
import com.esrx.services.pbb.pojo.UserInfo;
import com.esrx.services.pbb.pojo.UserInfoResponse;
import com.esrx.services.pbb.repository.BenefitSetUpRepository;
import com.esrx.services.pbb.utils.PBBConfigServerParams;
import com.esrx.services.pbb.utils.PBBServiceConstants;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

@Component
@Slf4j
public class PbbService {
	@Autowired
	PBBConfigServerParams pbbConfigServerParams;

	@Autowired
	BenefitSetUpRepository benefitSetUpRepository;
//	@Autowired
//	RestTemplate restTemplate;

	// Method to read the user information received from SAML response.
	public UserInfoResponse getUserDetails() {
		log.info("FE Service.getUserDetails: Getting user Info from Okta");
		UserInfoResponse userResponseInfo = new UserInfoResponse();
		UserInfo userResponse = new UserInfo();
		userResponse.setUserId("P57026");
		userResponse.setFirstName("Rahul");
		userResponse.setLastName("Ranjan");
		userResponse.setEmailId("rahul_ranjan@express-scripts.com");
		userResponse.setGroupNames(PBBServiceConstants.ADMIN);
		userResponse.setEnvironment(pbbConfigServerParams.environment);
		userResponseInfo.setStatusCode(PBBServiceConstants.SUCCESS_STATUS_CODE);
		userResponseInfo.setStatusMessage(PBBServiceConstants.SUCCESS_STATUS_MSG);
		userResponseInfo.setUserInfo(userResponse);
		log.info("PbbService.getUserDetails: user Info: {}",userResponseInfo);
		return userResponseInfo;
	}
	// method to retrieve Benefit set up information
	public List<BenefitSetUp> getBenefitSetUp(){
		log.info("PBBService.getAllBenefitSetUp : start to search data");
		List<BenefitSetUp> results = new ArrayList<>();
		try{
			results = benefitSetUpRepository.findAll();
		}catch (Exception exe){
			log.info("Exception Occured While fetching data from DB:",exe.getMessage());
			exe.printStackTrace();
		}
		log.info("PBBService.getAllBenefitSetUp : list:{}",results);
		return results;
	}
	//method to retrive information about question id from elevate
//	public ResponseEntity getQuestionIdInfo(String id) {
//		log.info("insidePbbService.getQuestionIdInfo");
//		ResponseEntity responseEntity=null;
//		String url=" "+"/"+id;
//		log.info("PbbService.getQuestionIdInfo:URl:=>{}",url);
//		responseEntity=restTemplate.getForEntity(url,String.class);
//		return responseEntity;
//	}


}