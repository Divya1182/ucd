package com.esrx.services.pbb.repository;

import com.esrx.services.pbb.domain.BenefitSetUp;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface BenefitSetUpRepository extends JpaRepository<BenefitSetUp,Integer> {

    List<BenefitSetUp> findAll();
}
