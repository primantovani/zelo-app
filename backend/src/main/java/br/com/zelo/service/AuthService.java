package br.com.zelo.service;

import br.com.zelo.domain.Usuario;
import br.com.zelo.dto.ApiDtos.*;
import br.com.zelo.repository.UsuarioRepository;
import br.com.zelo.security.JwtService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {
    private final UsuarioRepository repo; private final PasswordEncoder encoder; private final JwtService jwt;
    public AuthService(UsuarioRepository r, PasswordEncoder e, JwtService j){repo=r;encoder=e;jwt=j;}
    @Transactional public AuthResponse registrar(RegisterRequest req) {
        if(repo.findByEmail(req.email()).isPresent()) throw new IllegalArgumentException("Este e-mail já está cadastrado.");
        Usuario u=new Usuario(); u.setNome(req.nome()); u.setEmail(req.email().toLowerCase()); u.setSenha(encoder.encode(req.senha())); u.setAtivo("S");
        u=repo.save(u); return new AuthResponse(jwt.generate(u.getEmail()),u.getId(),u.getNome(),u.getEmail());
    }
    public AuthResponse login(LoginRequest req) {
        Usuario u=repo.findByEmail(req.email().toLowerCase()).orElseThrow(()->new IllegalArgumentException("E-mail ou senha inválidos."));
        if(!"S".equals(u.getAtivo()) || !encoder.matches(req.senha(),u.getSenha())) throw new IllegalArgumentException("E-mail ou senha inválidos.");
        return new AuthResponse(jwt.generate(u.getEmail()),u.getId(),u.getNome(),u.getEmail());
    }
}
