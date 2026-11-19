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

    // CORS para o app Flutter Web. Origens permitidas em app.cors.origins
    // (variavel CORS_ORIGINS), separadas por virgula.
    @Bean org.springframework.web.cors.CorsConfigurationSource corsConfigurationSource(
            @org.springframework.beans.factory.annotation.Value("${app.cors.origins}") String origins) {
        var cfg = new org.springframework.web.cors.CorsConfiguration();
        cfg.setAllowedOriginPatterns(java.util.Arrays.stream(origins.split(",")).map(String::trim).toList());
        cfg.setAllowedMethods(java.util.List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        cfg.setAllowedHeaders(java.util.List.of("Authorization", "Content-Type"));
        var src = new org.springframework.web.cors.UrlBasedCorsConfigurationSource();
        src.registerCorsConfiguration("/**", cfg);
        return src;
    }
    @Bean SecurityFilterChain filterChain(HttpSecurity http, JwtFilter jwtFilter) throws Exception {
        return http.csrf(csrf->csrf.disable())
            .cors(org.springframework.security.config.Customizer.withDefaults())
            .sessionManagement(s->s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(a->a
                .requestMatchers("/auth/**","/actuator/health").permitAll()
                .requestMatchers(HttpMethod.GET,"/categorias","/categorias/**","/ocorrencias","/ocorrencias/{id}","/ocorrencias/protocolo/{protocolo}","/ocorrencias/usuario/{idUsuario}").permitAll()
                .anyRequest().authenticated())
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class).build();
    }
}
