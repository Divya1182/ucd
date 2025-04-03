package com.esrx.services.pbb.domain;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

import javax.persistence.*;
import java.io.Serializable;
import java.util.List;

@Entity
@Data
@JsonIgnoreProperties
@Table(schema = "phbb_db", name = "BENEFIT_SETUP")
public class BenefitSetUp implements Serializable {

    @Id
    @Column(name="SETUP_RESOURCE_ID", nullable = false)
    private int setupResourceId;

    @Column(name="SETUP_TYPE", nullable = false)
    private String setupType;

    @OneToMany(mappedBy="setupResourceId", fetch=FetchType.EAGER)
    private List<BenefitSetUpDetail> benefitSetUpDetailList;
}
