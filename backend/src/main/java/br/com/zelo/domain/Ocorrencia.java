package br.com.zelo.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity @Table(name = "OCORRENCIA")
public class Ocorrencia {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) @Column(name = "ID_OCORRENCIA")
    private Long id;
    @Column(name = "ID_USUARIO", nullable = false) private Long idUsuario;
    @Column(name = "ID_CATEGORIA", nullable = false) private Long idCategoria;
    @Column(name = "TITULO", nullable = false) private String titulo;
    @Column(name = "DESCRICAO") private String descricao;
    @Column(name = "LATITUDE") private Double latitude;
    @Column(name = "LONGITUDE") private Double longitude;
    @Column(name = "ENDERECO") private String endereco;
    @Column(name = "PROTOCOLO", unique = true) private String protocolo;
    @Column(name = "STATUS_ATUAL") private String statusAtual;
    @Column(name = "DATA_ABERTURA") private LocalDateTime dataAbertura;

    public Long getId(){return id;} public Long getIdUsuario(){return idUsuario;} public Long getIdCategoria(){return idCategoria;}
    public String getTitulo(){return titulo;} public String getDescricao(){return descricao;}
    public Double getLatitude(){return latitude;} public Double getLongitude(){return longitude;}
    public String getEndereco(){return endereco;} public String getProtocolo(){return protocolo;}
    public String getStatusAtual(){return statusAtual;} public LocalDateTime getDataAbertura(){return dataAbertura;}
}
