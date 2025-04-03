/**
 * Controller class.
 * starting point of all API under PBB service component
 * @author P57026
 */
package com.esrx.services.pbb.controller;


import com.esrx.services.pbb.domain.BenefitSetUp;
import com.esrx.services.pbb.pojo.IdpLocation;
import com.esrx.services.pbb.pojo.UserInfoResponse;
import com.esrx.services.pbb.service.PbbService;
import com.esrx.services.pbb.utils.PBBServiceConstants;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import static org.springframework.http.MediaType.APPLICATION_JSON_VALUE;
import com.esrx.services.pbb.utils.PBBConfigServerParams;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.PostConstruct;

@Slf4j
@RestController
@RequestMapping(value = "/pbb/v1/benefits")
public class PharmacyBenefitsBuildController {
    @Autowired
    PBBConfigServerParams pbbConfigServerParams;

    @Autowired
    PbbService pbbService;

    // version api will provide the application version information
    @GetMapping(value = "/ping", produces = {APPLICATION_JSON_VALUE})
    public String get() {
        return "!!!!Welcome to Pharmacy Benefits Builder SERVICE!!!!";
    }

    @GetMapping(value = "/version", produces = {APPLICATION_JSON_VALUE})
    public ResponseEntity appController() {
        log.info("Inside PharmacyBenefitsBuildController.appController");
        Map<String, String> resp = new HashMap<>();
        resp.put("Application Name", pbbConfigServerParams.appName);
        resp.put("Current Application Version", pbbConfigServerParams.appVersion);
        resp.put("Service Status is"+ pbbConfigServerParams.status +" in", pbbConfigServerParams.environment);
        return ResponseEntity.ok(resp);
    }

    @GetMapping(value = "/user/userInfo", produces = {APPLICATION_JSON_VALUE})
    public UserInfoResponse getUserDetails() {
        log.info("Inside PharmacyBenefitsBuildController.getUserDetails");
        UserInfoResponse userResponseInfo=pbbService.getUserDetails();
        return userResponseInfo;
    }

    @GetMapping(value = "/idpLocation", produces = {APPLICATION_JSON_VALUE})
    public IdpLocation getIdpLocation() {
        IdpLocation response= new IdpLocation();
        response.setStatusCode(PBBServiceConstants.SUCCESS_STATUS_CODE);
        return response;
    }

    @PostConstruct
    @GetMapping(value="/preload/benefitSetups", produces = {APPLICATION_JSON_VALUE})
    public ResponseEntity getAllBenefitSetUp(){
        List<BenefitSetUp> benefitSetUpTypes=pbbService.getBenefitSetUp();
        HashMap<String,Object> responseMap= new HashMap<String,Object>();
        if(!benefitSetUpTypes.isEmpty()){
            responseMap.put("statusCode",PBBServiceConstants.SUCCESS_STATUS_CODE);
            responseMap.put("statusMessage",PBBServiceConstants.SUCCESS_STATUS_MSG);
            responseMap.put("benefitSetUpTypes",benefitSetUpTypes);
            return ResponseEntity.ok(responseMap);
        }else{
            responseMap.put("statusCode",PBBServiceConstants.NO_RECORD_FOUND_CODE);
            responseMap.put("statusMessage",PBBServiceConstants.NO_RECORD_FOUND);
            return ResponseEntity.ok(responseMap);
        }
    }

//    @GetMapping(value="/elevate/{Id}",produces={APPLICATION_JSON_VALUE})
//    public ResponseEntity getInfoForQuestionId(@PathVariable String id) {
//        log.info("InsidePharmacyBenfitsBuildController.getInfoForQuestionId");
//        ResponseEntity response=null;
//        try{
//            response=pbbService.getQuestionIdInfo(id);
//        }catch(Exception ex)
//        {
//            log.info("PharmacyBenefitsBuildController.getInfoForQuestionId::ExceptionOccured::=>",ex.getStackTrace());
//        }
//        return response;
//    }
}