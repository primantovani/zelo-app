package br.com.zelo.security;

import br.com.zelo.repository.UsuarioRepository;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;
import java.util.List;

@Component
public class JwtFilter extends OncePerRequestFilter {
    private final JwtService jwtService; private final UsuarioRepository usuarios;
    public JwtFilter(JwtService jwtService, UsuarioRepository usuarios){this.jwtService=jwtService;this.usuarios=usuarios;}
    @Override protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
        throws ServletException, IOException {
        String h=req.getHeader("Authorization");
        if(h!=null && h.startsWith("Bearer ")) {
            try {
                String email=jwtService.extractSubject(h.substring(7));
                if(SecurityContextHolder.getContext().getAuthentication()==null && usuarios.findByEmail(email).isPresent()) {
                    var auth=new UsernamePasswordAuthenticationToken(email,null,List.of(new SimpleGrantedAuthority("ROLE_USER")));
                    SecurityContextHolder.getContext().setAuthentication(auth);
                }
            } catch(Exception ignored) { SecurityContextHolder.clearContext(); }
        }
        chain.doFilter(req,res);
    }
}
