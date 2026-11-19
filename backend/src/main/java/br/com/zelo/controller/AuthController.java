package br.com.zelo.controller;
import br.com.zelo.dto.ApiDtos.*;
import br.com.zelo.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

@RestController @RequestMapping("/auth")
public class AuthController {
    private final AuthService service; public AuthController(AuthService s){service=s;}
    @PostMapping("/registrar") public AuthResponse registrar(@Valid @RequestBody RegisterRequest r){return service.registrar(r);}
    @PostMapping("/login") public AuthResponse login(@Valid @RequestBody LoginRequest r){return service.login(r);}
}
