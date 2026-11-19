package br.com.zelo.domain;

import jakarta.persistence.*;

@Entity @Table(name = "FOTO_OCORRENCIA")
public class FotoOcorrencia {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) @Column(name = "ID_FOTO")
    private Long id;
    @Column(name = "ID_OCORRENCIA", nullable = false) private Long idOcorrencia;
    @Column(name = "URL_FOTO", nullable = false) private String urlFoto;
    public Long getId(){return id;} public Long getIdOcorrencia(){return idOcorrencia;}
    public String getUrlFoto(){return urlFoto;} public void setIdOcorrencia(Long v){idOcorrencia=v;}
    public void setUrlFoto(String v){urlFoto=v;}
}
