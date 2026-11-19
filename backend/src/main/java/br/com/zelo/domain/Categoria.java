package br.com.zelo.domain;

import jakarta.persistence.*;

@Entity @Table(name = "CATEGORIA")
public class Categoria {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) @Column(name = "ID_CATEGORIA")
    private Long id;
    @Column(name = "NOME", nullable = false) private String nome;
    @Column(name = "DESCRICAO") private String descricao;
    @Column(name = "ATIVO") private String ativo = "S";

    public Long getId(){return id;} public String getNome(){return nome;} public void setNome(String v){nome=v;}
    public String getDescricao(){return descricao;} public void setDescricao(String v){descricao=v;}
    public String getAtivo(){return ativo;} public void setAtivo(String v){ativo=v;}
}
