package com.esrx.services.pbb.domain;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.Table;
import java.io.Serializable;

@Entity
@Data
@JsonIgnoreProperties
@Table(schema = "phbb_db", name = "BENEFIT_SETUP_DETAIL")
public class BenefitSetUpDetail implements Serializable {

    @Column(name="SETUP_RESOURCE_ID", nullable = false)
    private int setupResourceId;
    @Column(name="SETUP_NAME", nullable = false)
    private String setupName;

    @Id
    @Column(name="ELEVATE_RULES_JSON_REF_ID", nullable = false)
    private String elevateId;

}
