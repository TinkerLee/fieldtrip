function test_headmodel_dipoli_new_old

% MEM 1500mb
% WALLTIME 00:10:00

% DEPENDENCY ft_headmodel_dipoli mesh_sphere ft_prepare_vol_sens ft_compute_leadfield

% tests the old and new version of dipoli wrapper

% generate a unit sphere
[pnt, tri] = mesh_sphere(162);

% create the BEM geometries
geom = [];
geom.bnd(1).pnt = pnt * 100;
geom.bnd(1).tri = tri;
geom.bnd(2).pnt = pnt * 90;
geom.bnd(2).tri = tri;
geom.bnd(3).pnt = pnt * 80;
geom.bnd(3).tri = tri;

elec.chanpos = pnt * 100;
elec.elecpos = pnt * 100;
for i=1:size(pnt,1)
  elec.label{i} = sprintf('%d', i);
end

arg(1).name = 'conductivity';
arg(1).value = {[], [1 1/20 1], [0.33 0.125 0.33], [1 1 1], [0.1 0.1 0.1]};

arg(2).name = 'isolatedsource';
arg(2).value = {'yes' , 'no'};

optarg = constructalloptions(arg);

for i=1:size(optarg,1)
  
  vol = {};
  arg = optarg(i,:);
  
  % new way - low level:
  vol{1} = ft_headmodel_dipoli(geom.bnd,arg{:});

  % old way:
  tmpcfg = ft_keyval2cfg(arg{:});
  tmpcfg.method = 'dipoli';
  vol{2} = ft_prepare_bemmodel(tmpcfg,geom);
  vol{2} = rmfield(vol{2},'unit');
  
  % new way - high level:
  tmpcfg = ft_keyval2cfg(arg{:});
  tmpcfg.method = 'bem_dipoli';
  vol{3} = ft_prepare_headmodel(tmpcfg,geom.bnd);
  vol{3} = rmfield(vol{3},'unit');
  
  % compute the leadfields for a comparison
  [vol{1}, elec] = ft_prepare_vol_sens(vol{1}, elec);
  [vol{2}, elec] = ft_prepare_vol_sens(vol{2}, elec);
  [vol{3}, elec] = ft_prepare_vol_sens(vol{3}, elec);
  lf{1} = ft_compute_leadfield([0 10 60], elec, vol{1});
  lf{2} = ft_compute_leadfield([0 10 60], elec, vol{2});
  lf{3} = ft_compute_leadfield([0 10 60], elec, vol{3});
  
  % compare the leadfields in all possible combinations
  comb = nchoosek(1:numel(vol),2);
  for j=1:size(comb,1)
    chk = comb(j,:);
    err = norm(lf{chk(1)} - lf{chk(2)}) / norm(lf{chk(1)});
    if err>0.001
      error('combination %d %d not successful\n',chk(1),chk(2));
    end
  end
  
end
