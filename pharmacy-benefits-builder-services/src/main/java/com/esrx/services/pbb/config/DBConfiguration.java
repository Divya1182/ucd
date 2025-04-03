package com.esrx.services.pbb.config;

import com.esrx.services.pbb.utils.PBBConfigServerParams;
import com.zaxxer.hikari.HikariDataSource;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.orm.jpa.EntityManagerFactoryBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.util.ResourceUtils;

import javax.sql.DataSource;
import java.util.ServiceConfigurationError;


@Slf4j
@Configuration
@EnableJpaRepositories(basePackages = "com.esrx.services.pbb", entityManagerFactoryRef = "entityManagerFactory",
        transactionManagerRef = "postgresTransactionManager")
public class DBConfiguration {
    @Autowired
    PBBConfigServerParams pbbConfigServerParams;

    @Bean(name = "postgresDataSourceProperties")
    @Primary
    @ConfigurationProperties(prefix = "spring.postgres.datasource")
    public DataSourceProperties postgresDataSourceProperties() {
        DataSourceProperties prop = new DataSourceProperties();
        prop.setUrl(createSSLJdbcUrl());
        return prop;
    }

    public String createSSLJdbcUrl() {
        var url = new StringBuilder();
        try {
            url.append(pbbConfigServerParams.pgURL)
                    .append("?")
                    .append("ssl=").append(pbbConfigServerParams.sslTrue)
                    .append("&sslcompression=").append(pbbConfigServerParams.sslCompression)
                    .append("&sslmode=").append(pbbConfigServerParams.sslMode)
                    .append("&sslpassword=").append(pbbConfigServerParams.sslPwd)
                    .append("&sslkey=").append(ResourceUtils.getFile(pbbConfigServerParams.sslKey).getPath())
                    .append("&sslcert=").append(ResourceUtils.getFile(pbbConfigServerParams.sslCert).getPath())
                    .append("&sslrootcert=").append(ResourceUtils.getFile(pbbConfigServerParams.sslRootCert).getPath());
        } catch (java.io.FileNotFoundException ex) {
            throw new ServiceConfigurationError(
                    String.format("Error building URL context: %s, %s. Exiting", ex.getClass(), ex.getMessage()), ex);
        }
        log.info("DBConfiguration.createSSLJdbcUrl=> connection url=>" + url.toString());
        return url.toString();
    }

    @Bean(name = "postgresDataSource")
    @Primary
    @ConfigurationProperties(prefix = "spring.postgres.datasource.hikari")
    public DataSource postgresDataSource() {
        return postgresDataSourceProperties().initializeDataSourceBuilder().type(HikariDataSource.class).build();
    }

    @Bean(name = "postgresTransactionManager")
    @Primary
    public DataSourceTransactionManager postgresTransactionManager(@Qualifier("postgresDataSource") DataSource postgresDataSource) {
        return new DataSourceTransactionManager(postgresDataSource);
    }

    @Bean(name ="entityManagerFactory")
    @Primary
    public LocalContainerEntityManagerFactoryBean entityManagerFactory (EntityManagerFactoryBuilder builder)  {
            return builder.dataSource(postgresDataSource())
                .packages("com.esrx.services.pbb")
                .persistenceUnit("postgresUnit")
                .build();
    }
//    @Bean(name = "postgresJdbcTemplate")
//    @Primary
//    public JdbcTemplate postgresJdbcTemplate(@Qualifier("postgresDataSource") DataSource postgresDataSource) {
//        return new JdbcTemplate(postgresDataSource);
//    }
//
//    @Bean(name = "postgresNamedJdbcTemplate")
//    @Primary
//    public NamedParameterJdbcTemplate postgresNamedJdbcTemplate(@Qualifier("postgresDataSource") DataSource postgresDataSource) {
//        return new NamedParameterJdbcTemplate(postgresDataSource);
//    }
}