unit objects; {$MODE OBJFPC} {$COPERATORS ON} {$WRITEABLECONST OFF}

interface
   uses SysUtils, Sour;

Type  TFacing = 0..1;
Const FACE_RIGHT = 0; FACE_LEFT = 1;

Type // Basic class for all in-game entities
     PEntity = ^TEntity;
     TEntity = Object
     Private
       fX, fY : Double;      //floating-point position
       intX, intY : LongInt; //integer position
       mapX, mapY : LongInt; //map (room) position

       Procedure Set_fX(newX:Double);
       Procedure Set_fY(newY:Double);
       Procedure Set_iX(newX:LongInt);
       Procedure Set_iY(newY:LongInt);
       Procedure Set_mX(newX:LongInt);
       Procedure Set_mY(newY:LongInt); //army of setters, duh

     Public
       Gfx : Sour.PImage;    // Pointer to a Sour Picture
       Col : Sour.PColour;   // Pointer to a Sour Colour
       XVel, YVel : Double;  // X,Y velocity
       XCol, YCol : Boolean; // X,Y collision
       W, H : LongWord;      // Width and height
       HP  : Double;         // Health points
       Enemy : Boolean;      // Team indicator
       Face : TFacing;       // Facing
       SfxID : LongInt;      // Death SFX ID. <0 means none.
       SwitchNum : LongInt;  // Switch to trigger on death

       Function GetCrd:Sour.TCrd; //fart out a Sour Coordinate

       Property X:Double read fX write Set_fX;
       Property Y:Double read fY write Set_fY;
       Property iX:LongInt read intX write Set_iX;
       Property iY:LongInt read intY write Set_iY;
       Property mX:LongInt read mapX write Set_mX;
       Property mY:LongInt read mapY write Set_mY;

       Procedure Calculate(dt:LongWord); Virtual;

       Constructor Create;
       Destructor Destroy; Virtual;
     end;

     // Bullet, duh
     PBullet = ^TBullet;
     TBullet = Object(TEntity)
     Public
       Power : Double;

       Constructor Create(Index:LongWord);
       Destructor Destroy; Virtual;
     end;

     // Remains - after killing an enemy or dying
     PGib = ^TGib;
     TGib = Object(TEntity)
     Public
       Rect : Sour.TRect;
       Constructor Create(pX,pY,pW,pH:LongWord);
       Destructor Destroy; Virtual;
     end;

     // Player Object
     PPlayer = ^TPlayer;
     TPlayer = Object(TEntity)
     Public
       FireTimer : LongInt;
       InvTimer  : LongInt;
       MaxHP     : Double;
       FirePower : Double;
       InvLength : LongWord;

       Procedure Calculate(dt:LongWord); Virtual;

       Constructor Create;
       Destructor Destroy; Virtual;
     end;

     // Drone, a basic enemy
     PDrone = ^TDrone;
     TDrone = Object(TEntity)
     Private
       Chase : Boolean;
       Timer : LongInt;
     Public
       Procedure Calculate(dt:LongWord); Virtual;

       Constructor Create;
       Destructor Destroy; Virtual;
     end;

     // Basher, another basic enemy
     PBasher = ^TBasher;
     TBasher = Object(TEntity)
     Private
       Dir : LongWord;
       Bash : Boolean;
       Timer : LongInt;
     Public
       Procedure Calculate(dt:LongWord); Virtual;

       Constructor Create;
       Destructor Destroy; Virtual;
     end;

     // Ball, yet another enemy
     PBall = ^TBall;
     TBall = Object(TEntity)
     Public
       Procedure Calculate(dt:LongWord); Virtual;

       Constructor Create;
       Destructor Destroy; Virtual;
     end;

     // All right, let's try an enemy that can shoot
     PSpitter = ^TSpitter;
     TSpitter = Object(TEntity)
     Private
       FireTimer, MoveTimer : LongInt;
       Move : Boolean;
     Public
       Procedure Calculate(dt:LongWord); Virtual;

       Constructor Create;
       Destructor Destroy; Virtual;
     end;

     // An enemy that spams the map with bullets
     PSpammer = ^TSpammer;
     TSpammer = Object(TEntity)
     Private
       FireTimer, MoveTimer : LongInt;
       Angle : Double;
     Public
       Procedure Calculate(dt:LongWord); Virtual;

       Constructor Create;
       Destructor Destroy; Virtual;
     end;

     // Energy generator
     PGenerator = ^TGenerator;
     TGenerator = Object(TEntity)
     Private
       BigTimer,SmallTimer : LongInt;
     Public
       Procedure Calculate(dt:LongWord); Virtual;

       Constructor Create;
       Destructor Destroy; Virtual;
     end;

     // Turret, doh
     PTurret = ^TTurret;
     TTurret = Object(TEntity)
     Private
       NorTime,SpamTime : LongInt;
     Public
       Procedure Calculate(dt:LongWord); Virtual;

       Constructor Create;
       Destructor Destroy; Virtual;
     end;

implementation
   uses Shared;

Const TwoRoot = Sqrt(2);

Function TEntity.GetCrd:Sour.TCrd;
   begin Exit(Sour.MakeCrd(intX,intY)) end;

Procedure TEntity.Set_fX(newX:Double);
   begin fX:=newX; intX:=Trunc(fX); mapX:=Trunc(fX / TILE_W) end;

Procedure TEntity.Set_fY(newY:Double);
   begin fY:=newY; intY:=Trunc(fY); mapY:=Trunc(fY / TILE_H) end;

Procedure TEntity.Set_iX(newX:LongInt);
   begin fX:=newX; intX:=newX; mapX:=Trunc(fX / TILE_W) end;

Procedure TEntity.Set_iY(newY:LongInt);
   begin fY:=newY; intY:=newY; mapY:=Trunc(fY / TILE_H) end;

Procedure TEntity.Set_mX(newX:LongInt);
   begin mapX:=newX; iX:=newX*Tile_W; fX:=iX end;

Procedure TEntity.Set_mY(newY:LongInt);
   begin mapY:=newY; iY:=newY*Tile_H; fY:=iY end;

Procedure TEntity.Calculate(dt:LongWord);
   begin end; //By default, an entity does nothing

Constructor TEntity.Create();
   begin
   Set_fX(0); Set_fY(0);
   Gfx:=NIL; Col:=NIL;
   W:=TILE_W; H:=TILE_H;
   XCol:=False; YCol:=False;
   SfxID:=(-1); SwitchNum:=(-1)
   end;

Destructor TEntity.Destroy();
   begin end;

Constructor TGib.Create(pX,pY,pW,pH:LongWord);
   begin
   With Rect do begin X:=pX; Y:=pY; W:=pW; H:=pH end;
   Self.W:=pW; Self.H:=pH; HP:=3
   end;

Destructor TGib.Destroy();
   begin Inherited Destroy end;

Constructor TBullet.Create(Index:LongWord);
   begin Inherited Create();
   Gfx:=ShotGfx[Index];
   W:=Gfx^.W div 2; H:=Gfx^.H;
   end;

Destructor TBullet.Destroy();
   begin Inherited Destroy();
   end;

Procedure TPlayer.Calculate(dt:LongWord);
   Const FireInterval = 250;
   begin
   XVel:=0; YVel:=0;
   If (Key[KEY_UP   ]) then YVel-=HERO_SPEED;
   If (Key[KEY_DOWN ]) then YVel+=HERO_SPEED;
   If (Key[KEY_LEFT ]) then XVel-=HERO_SPEED;
   If (Key[KEY_RIGHT]) then XVel+=HERO_SPEED;
   If (XVel<>0) and (YVel<>0) then begin XVel/=TwoRoot; YVel/=TwoRoot end;
   If (FireTimer > 0) then FireTimer-=dt
      else begin
      If (Key[KEY_Z]) then begin
         Face:=FACE_LEFT; PlaySfx(SFX_SHOT+2);
         FireTimer:=FireInterval+FireTimer;
         PlaceBullet(@Self,(-2)*HERO_SPEED,0,FirePower,2)
         end else
      If (Key[KEY_X]) then begin
         FACE:=FACE_RIGHT; PlaySfx(SFX_SHOT+2);
         FireTimer:=FireInterval+FireTimer;
         PlaceBullet(@Self,(+2)*HERO_SPEED,0,FirePower,2)
         end else
      end;
   If (InvTimer > 0) then InvTimer-=dt
   end;

Constructor TPlayer.Create();
   begin Inherited Create();
   Gfx:=CharaGfx[GFX_HERO];
   Col:=@GreyColour;
   MaxHP:=HERO_HEALTH; HP:=MaxHP;
   FirePower:=HERO_FIREPOWER; InvLength := HERO_INVUL;
   Enemy:=False
   end;

Destructor TPlayer.Destroy();
   begin Inherited Destroy();
   end;

Procedure TDrone.Calculate(dt:LongWord);
   Const ChaseTime = 800; IdleTime = 200;
         Spd = TILE_S * 3;
   Var Dist : Double;
   begin
   If (Timer > 0) then begin
      Timer-=dt;
      If (Chase) then begin
         If (XCol) then XVel:=-XVel;
         If (YCol) then YVel:=-YVel;
         end
      end else begin
      If (Chase) then begin
         Chase:=False; Timer:=IdleTime+Timer;
         XVel:=0; YVel:=0
         end else begin
         Chase:=True; Timer:=ChaseTime+Timer;
         GetDist(@Self,Hero,XVel,YVel,Dist);
         XVel:=XVel/Dist*Spd;
         YVel:=YVel/Dist*Spd
         end
      end
   end;

Constructor TDrone.Create();
   begin Inherited Create();
   Gfx:=CharaGfx[GFX_ENEM]; SfxID:=SFX_DIE+3;
   Chase:=False; Timer:=100;
   HP:=5.75; Enemy:=True
   end;

Destructor TDrone.Destroy();
   begin Inherited Destroy();
   end;

Procedure TBasher.Calculate(dt:LongWord);
   Const ChaseTime = 1500; IdleTime = 100;
         Spd = TILE_S * 8; AccelTime = 150;
   Var XD,YD, Perc : Double;
   begin
   If (Timer > 0) then begin
      Timer-=dt;
      If (Bash) then begin
         If (XCol) or (YCol) then Case Dir of
            2: Dir:=4; 4: Dir:=6; 6: Dir:=4; 8: Dir:=2 end;
         If (Timer<AccelTime) then Perc:=(Timer/AccelTime) else
         If (Timer>ChaseTime-AccelTime) then Perc:=((ChaseTime-Timer)/AccelTime) else
            {else} Perc:=1;
         Case Dir of
            2: YVel:=(+Perc)*Spd; 8: YVel:=(-Perc)*Spd;
            4: XVel:=(-Perc)*Spd; 6: XVel:=(+Perc)*Spd
            end
         end
      end else begin
      If (Bash) then begin
         Bash:=False; Timer:=IdleTime+Timer;
         XVel:=0; YVel:=0
         end else begin
         Bash:=True; Timer:=ChaseTime+Timer;
         XD:=(Hero^.X-Self.X); YD:=(Hero^.Y-Self.Y);
         If (Abs(XD)>Abs(YD)) or (Random(4)=0)
            then if (XD>0) then Dir:=6 else Dir:=4
            else if (YD>0) then Dir:=2 else Dir:=8
         end
      end
   end;

Constructor TBasher.Create();
   begin Inherited Create();
   Gfx:=CharaGfx[GFX_ENEM+3]; SfxID:=SFX_DIE+3;
   Bash:=False; Timer:=100;
   HP:=16; Enemy:=True
   end;

Destructor TBasher.Destroy();
   begin Inherited Destroy();
   end;

Procedure TBall.Calculate(dt:LongWord);
   Const Spd = TILE_S / 6;
   Var Dist : Double;
   begin
   If (XCol) then XVel:=-XVel;
   If (YCol) then YVel:=-YVel;
   Dist:=Hypotenuse(@Self,Hero);
   XVel+=(Hero^.X-Self.X)/Dist*Spd;
   YVel+=(Hero^.Y-Self.Y)/Dist*Spd;
   end;

Constructor TBall.Create();
   begin Inherited Create();
   Gfx:=CharaGfx[GFX_ENEM+2]; SfxID:=SFX_DIE+2;
   HP:=9.75; Enemy:=True
   end;

Destructor TBall.Destroy();
   begin Inherited Destroy();
   end;

Procedure TSpitter.Calculate(dt:LongWord);
   Const MoveTime = 444; IdleTime = 100; FireInterval = 1200;
         Spd = TILE_S * 2.4;
   Var Dist : Double;
   begin
   If (FireTimer > 0) then FireTimer-=dt
      else begin
      PlaySfx(SFX_SHOT);
      FireTimer:=FireInterval+FireTimer;
      PlaceBullet(@Self,Sgn(Hero^.X-Self.X)*TILE_S*4,0,5,0)
      end;
   If (MoveTimer > 0) then begin
      MoveTimer-=dt;
      If (Move) then begin
         If (XCol) then XVel:=-XVel;
         If (YCol) then YVel:=-YVel;
         end
      end else begin
      If (Move) then begin
         Move:=False; MoveTimer:=IdleTime+MoveTimer;
         XVel:=0; YVel:=0
         end else begin
         Move:=True; MoveTimer:=MoveTime+MoveTimer;
         GetDist(@Self,Hero,XVel,YVel,Dist);
         XVel:=XVel/Dist*Spd;
         YVel:=YVel/Dist*Spd
         end
      end
   end;

Constructor TSpitter.Create();
   begin Inherited Create();
   Gfx:=CharaGfx[GFX_ENEM+1]; SfxID:=SFX_DIE+4;
   Move:=False; MoveTimer:=100; FireTimer:=1000;
   HP:=12; Enemy:=True
   end;

Destructor TSpitter.Destroy();
   begin Inherited Destroy();
   end;

Procedure TSpammer.Calculate(dt:LongWord);
   Const MoveMin = 500; MoveMax = 700; FireInterval = 800;
         Spd = TILE_S * 1.5;
   begin
   If (FireTimer > 0) then FireTimer-=dt
      else begin
      PlaySfx(SFX_SHOT+1);
      FireTimer:=FireInterval+FireTimer;
      PlaceBullet(@Self,TILE_S*(+6),0,5,0); PlaceBullet(@Self,TILE_S*(-6),0,5,0);
      PlaceBullet(@Self,0,TILE_S*(+6),5,0); PlaceBullet(@Self,0,TILE_S*(-6),5,0);
      end;
   If (MoveTimer > 0) then begin
      MoveTimer-=dt;
      If (XCol) then XVel:=-XVel;
      If (YCol) then YVel:=-YVel;
      end else begin
      MoveTimer:=Random(MoveMin,MoveMax)+MoveTimer;
      Angle+=(Random(2001)-1000)*Pi/2000;
      XVel:=Cos(Angle)*Spd;
      YVel:=Sin(Angle)*Spd
      end
   end;

Constructor TSpammer.Create();
   begin Inherited Create();
   Gfx:=CharaGfx[GFX_ENEM+4]; SfxID:=SFX_DIE+4;
   MoveTimer:=100; FireTimer:=1000;
   Angle:=Random(2000)*Pi/1000;
   HP:=18; Enemy:=True
   end;

Destructor TSpammer.Destroy();
   begin Inherited Destroy();
   end;

Procedure TGenerator.Calculate(dt:LongWord);
   Const BigMin = 1500; BigMax = 2500; SmaMin = 700; SmaMax = 1000;
         BigSpd = HERO_SPEED * 1.75; SmaSpd = HERO_SPEED * 1.25;
   Var Dist,XV,YV:Double; BulNum:LongWord;
   begin
   If (BigTimer > 0) then BigTimer-=dt else begin
      BigTimer:=Random(BigMin,BigMax)+BigTimer;
      GetDist(@Self,Hero,XV,YV,Dist);
      XV:=XV/Dist*BigSpd; YV:=YV/Dist*BigSpd;
      PlaceBullet(@Self,XV,YV,12,4);
      If (Random(2)=0)
         then PlaceBullet(@Self,XV*1.1,YV/1.1,12,4)
         else PlaceBullet(@Self,XV/1.1,YV*1.1,12,4);
      end;
   If (SmallTimer > 0) then SmallTimer-=dt else begin
      SmallTimer:=Random(SmaMin,SmaMax)+SmallTimer;
      For BulNum:=1 to 5 do begin
         Dist:=Random(-600,600)*Pi/1800;
         If (Hero^.X<Self.X) then Dist+=Pi;
         PlaceBullet(@Self,Cos(Dist)*SmaSpd,Sin(Dist)*SmaSpd,4,3)
         end
      end;
   end;

Constructor TGenerator.Create();
   begin Inherited Create();
   Gfx:=CharaGfx[GFX_ENEM+5]; SfxID:=SFX_DIE+0;
   BigTimer:=2000; SmallTimer:=2000;
   HP:=64; Enemy:=True
   end;

Destructor TGenerator.Destroy();
   begin Inherited Destroy();
   end;

Procedure TTurret.Calculate(dt:LongWord);
   Const NorMin = 400; NorMax = 480; SpamMin = 3000; SpamMax = 4000;
         NorSpd = HERO_SPEED * 0.8; SpamSpd = HERO_SPEED * 1.2;
   Var Dist,XV,YV:Double; BulNum:LongWord;
   begin
   If (NorTime > 0) then NorTime-=dt else begin
      NorTime:=Random(NorMin,NorMax)+NorTime;
      GetDist(@Self,Hero,XV,YV,Dist);
      XV:=XV/Dist*NorSpd; YV:=YV/Dist*NorSpd;
      PlaceBullet(@Self,XV,YV,3,3)
      end;
   {If (SpamTime > 0) then SpamTime-=dt else begin
      SpamTime:=Random(SpamMin,SpamMax)+SpamTime;
      For BulNum:=1 to 8 do begin
         Dist:=Random(-500,500)*Pi/1800;
         If (Hero^.X<Self.X) then Dist+=Pi;
         PlaceBullet(@Self,Cos(Dist)*SpamSpd,Sin(Dist)*SpamSpd,4,0)
         end
      end;}
   end;

Constructor TTurret.Create();
   begin Inherited Create();
   Gfx:=CharaGfx[GFX_ENEM+6]; SfxID:=SFX_DIE+5;
   NorTime:=1000; SpamTime:=1800;
   HP:=27; Enemy:=True
   end;

Destructor TTurret.Destroy();
   begin Inherited Destroy();
   end;

end.

