package br.com.zelo.security;

import org.springframework.context.annotation.*;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.http.HttpMethod;

@Configuration
public class SecurityConfig {
    @Bean PasswordEncoder passwordEncoder(){return new BCryptPasswordEncoder();}
    @Bean SecurityFilterChain filterChain(HttpSecurity http, JwtFilter jwtFilter) throws Exception {
        return http.csrf(csrf->csrf.disable())
            .sessionManagement(s->s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(a->a
                .requestMatchers("/auth/**","/actuator/health").permitAll()
                .requestMatchers(HttpMethod.GET,"/categorias","/categorias/**","/ocorrencias","/ocorrencias/{id}","/ocorrencias/protocolo/{protocolo}","/ocorrencias/usuario/{idUsuario}").permitAll()
                .anyRequest().authenticated())
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class).build();
    }
}
