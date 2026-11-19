package br.com.zelo.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity @Table(name = "USUARIO")
public class Usuario {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) @Column(name = "ID_USUARIO")
    private Long id;
    @Column(name = "NOME", nullable = false) private String nome;
    @Column(name = "EMAIL", nullable = false, unique = true) private String email;
    @Column(name = "SENHA", nullable = false) private String senha;
    @Column(name = "ATIVO") private String ativo = "S";

    public Long getId(){return id;} public String getNome(){return nome;} public void setNome(String v){nome=v;}
    public String getEmail(){return email;} public void setEmail(String v){email=v;}
    public String getSenha(){return senha;} public void setSenha(String v){senha=v;}
    public String getAtivo(){return ativo;} public void setAtivo(String v){ativo=v;}
}
